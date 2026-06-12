#!/usr/bin/env python3
"""
Script para importar contactos desde CSV a la tabla personas de Mateos.
Normaliza números de teléfono para Uruguay (código 598).
"""

import csv
import re
import psycopg2
from psycopg2.extras import execute_values
from datetime import datetime

# Configuración de la base de datos
DB_CONFIG = {
    'host': 'localhost',
    'port': 1432,
    'database': 'asistente_db',
    'user': 'asistente',
    'password': 'n8npass'
}

CSV_PATH = '/home/azureuser/mateos/contacts (1).csv'


def normalizar_telefono(telefono: str) -> str:
    """
    Normaliza un número de teléfono según las reglas de Uruguay.

    Reglas:
    - Quitar espacios, guiones y caracteres especiales
    - Si empieza con +, quitar el +
    - Si empieza con 00 (llamada internacional), quitar los 00
    - Si empieza con 0 seguido de 9 (móvil uruguayo 09X), quitar el 0 y agregar 598
    - Si es 8 dígitos que empieza con 9 (móvil), agregar 598
    - Si empieza con 2 o 4 (fijo uruguayo), dejarlo como está
    - Si ya tiene código de país, dejarlo como está
    """
    if not telefono:
        return None

    # Limpiar: quitar espacios, guiones, paréntesis
    limpio = re.sub(r'[\s\-\(\)\.]', '', telefono)

    # Si tiene caracteres raros (*, letras, etc.), probablemente no es válido
    if re.search(r'[^\d\+]', limpio):
        # Intentar extraer solo dígitos después del +
        if limpio.startswith('+'):
            limpio = '+' + re.sub(r'[^\d]', '', limpio[1:])
        else:
            limpio = re.sub(r'[^\d]', '', limpio)

    # Si quedó vacío o muy corto, no es válido
    if not limpio or len(limpio) < 6:
        return None

    # Si empieza con +, quitar el +
    if limpio.startswith('+'):
        limpio = limpio[1:]

    # Si empieza con 00 (formato internacional), quitar los 00
    if limpio.startswith('00'):
        limpio = limpio[2:]

    # Si empieza con 0 y tiene 9 o 10 dígitos (móvil uruguayo con 0)
    # Ejemplos: 098440147 (9 dígitos), 0984401470 (10 dígitos)
    if limpio.startswith('0') and len(limpio) in [9, 10]:
        segundo_digito = limpio[1] if len(limpio) > 1 else ''
        # Si es móvil (09X), quitar el 0 y agregar 598
        if segundo_digito == '9':
            limpio = '598' + limpio[1:]
        # Si es fijo (02X, 04X), dejarlo como está (sin el 0 inicial para consistencia)
        elif segundo_digito in ['2', '4']:
            limpio = limpio[1:]  # Quitar el 0, dejar el número local

    # Si es 8 dígitos y empieza con 9 (móvil uruguayo sin código)
    elif len(limpio) == 8 and limpio.startswith('9'):
        limpio = '598' + limpio

    # Si es 7-8 dígitos y empieza con 2 o 4 (fijo uruguayo), dejarlo como está
    elif len(limpio) in [7, 8] and limpio[0] in ['2', '4']:
        pass  # Dejarlo como está

    # Si ya tiene 11+ dígitos y empieza con 598 (ya tiene código Uruguay)
    elif len(limpio) >= 11 and limpio.startswith('598'):
        pass  # Ya está normalizado

    # Si tiene 10+ dígitos y no empieza con 598, probablemente es internacional
    elif len(limpio) >= 10:
        pass  # Dejarlo como está (número internacional)

    return limpio if limpio else None


def es_movil_uruguay(telefono: str) -> bool:
    """Determina si un teléfono normalizado es móvil uruguayo (para WhatsApp)."""
    if not telefono:
        return False
    # Móvil uruguayo: 5989XXXXXXX (11 dígitos, empieza con 5989)
    return telefono.startswith('5989') and len(telefono) == 11


def construir_nombre_completo(row: dict) -> str:
    """Construye el nombre completo a partir de las partes."""
    partes = []

    first = row.get('First Name', '').strip()
    middle = row.get('Middle Name', '').strip()
    last = row.get('Last Name', '').strip()

    if first:
        partes.append(first)
    if middle:
        partes.append(middle)
    if last:
        partes.append(last)

    nombre = ' '.join(partes)

    # Si no hay nombre pero hay organización, usar eso
    if not nombre:
        org = row.get('Organization Name', '').strip()
        if org:
            nombre = org

    return nombre if nombre else None


def construir_otra_info(row: dict) -> str:
    """Construye el campo otra_informacion con datos adicionales."""
    partes = []

    org = row.get('Organization Name', '').strip()
    title = row.get('Organization Title', '').strip()
    dept = row.get('Organization Department', '').strip()
    notes = row.get('Notes', '').strip()
    labels = row.get('Labels', '').strip()

    if org:
        partes.append(f"Organización: {org}")
    if title:
        partes.append(f"Cargo: {title}")
    if dept:
        partes.append(f"Departamento: {dept}")
    if labels and labels != '* myContacts':
        # Limpiar labels
        labels_clean = labels.replace('* myContacts', '').replace(':::', ',').strip(' :,')
        if labels_clean:
            partes.append(f"Etiquetas: {labels_clean}")
    if notes:
        partes.append(f"Notas: {notes}")

    return '\n'.join(partes) if partes else None


def obtener_telefonos(row: dict) -> list:
    """Obtiene todos los teléfonos del contacto."""
    telefonos = []
    for i in range(1, 4):
        tel = row.get(f'Phone {i} - Value', '').strip()
        if tel:
            # Algunos tienen múltiples números separados por :::
            for t in tel.split(':::'):
                t = t.strip()
                if t:
                    telefonos.append(t)
    return telefonos


def obtener_emails(row: dict) -> list:
    """Obtiene todos los emails del contacto."""
    emails = []
    for i in range(1, 4):
        email = row.get(f'E-mail {i} - Value', '').strip()
        if email and '@' in email:
            emails.append(email)
    return emails


def procesar_contactos(csv_path: str) -> list:
    """Lee el CSV y procesa los contactos."""
    contactos = []

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        for row in reader:
            nombre = construir_nombre_completo(row)

            # Obtener teléfonos y normalizarlos
            telefonos_raw = obtener_telefonos(row)
            telefonos = [normalizar_telefono(t) for t in telefonos_raw]
            telefonos = [t for t in telefonos if t]  # Filtrar None

            # Obtener emails
            emails = obtener_emails(row)

            # Si no hay nombre ni teléfono ni email, saltar
            if not nombre and not telefonos and not emails:
                continue

            # Determinar teléfono principal y WhatsApp
            telefono_principal = telefonos[0] if telefonos else None
            whatsapp = None
            for t in telefonos:
                if es_movil_uruguay(t):
                    whatsapp = t
                    break

            # Si no hay nombre pero hay teléfono, usar teléfono como identificador temporal
            if not nombre and telefono_principal:
                nombre = f"Contacto {telefono_principal}"

            contacto = {
                'nombre_completo': nombre,
                'apodo': row.get('Nickname', '').strip() or None,
                'email': emails[0] if emails else None,
                'telefono': telefono_principal,
                'whatsapp': whatsapp,
                'otra_informacion': construir_otra_info(row)
            }

            # Solo agregar si tiene al menos nombre
            if contacto['nombre_completo']:
                contactos.append(contacto)

    return contactos


def truncar(valor: str, max_len: int) -> str:
    """Trunca un string al largo máximo."""
    if valor and len(valor) > max_len:
        return valor[:max_len]
    return valor


def insertar_contactos(contactos: list):
    """Inserta los contactos en la base de datos."""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    # Preparar datos para inserción (truncando a los límites del schema)
    valores = []
    for c in contactos:
        valores.append((
            truncar(c['nombre_completo'], 255),
            truncar(c['apodo'], 100),
            truncar(c['email'], 255),
            truncar(c['telefono'], 50),
            truncar(c['whatsapp'], 50),
            c['otra_informacion']  # TEXT, sin límite
        ))

    # Insertar con ON CONFLICT para evitar duplicados por nombre
    query = """
        INSERT INTO personas (nombre_completo, apodo, email, telefono, whatsapp, otra_informacion)
        VALUES %s
        ON CONFLICT DO NOTHING
    """

    execute_values(cur, query, valores)

    insertados = cur.rowcount
    conn.commit()
    cur.close()
    conn.close()

    return insertados


def main():
    print("=" * 60)
    print("IMPORTACIÓN DE CONTACTOS A TABLA PERSONAS")
    print("=" * 60)

    print(f"\nLeyendo CSV: {CSV_PATH}")
    contactos = procesar_contactos(CSV_PATH)
    print(f"Contactos procesados: {len(contactos)}")

    # Mostrar algunos ejemplos de normalización
    print("\n--- Ejemplos de normalización de teléfonos ---")
    ejemplos = [
        "098 440 147",
        "98916205",
        "+598 98 092 090",
        "59898440147",
        "2707 0268",
        "094431036",
        "+34 640 60 57 35",
        "0018432574556",
        "092 845 295"
    ]
    for ej in ejemplos:
        print(f"  {ej:25} -> {normalizar_telefono(ej)}")

    # Mostrar primeros 5 contactos como muestra
    print("\n--- Primeros 5 contactos a insertar ---")
    for i, c in enumerate(contactos[:5]):
        print(f"\n{i+1}. {c['nombre_completo']}")
        print(f"   Teléfono: {c['telefono']}")
        print(f"   WhatsApp: {c['whatsapp']}")
        print(f"   Email: {c['email']}")

    # Confirmar inserción
    print(f"\n¿Insertar {len(contactos)} contactos en la base de datos?")
    respuesta = input("Escribe 'si' para confirmar: ")

    if respuesta.lower() == 'si':
        insertados = insertar_contactos(contactos)
        print(f"\nContactos insertados: {insertados}")
    else:
        print("\nImportación cancelada.")


if __name__ == '__main__':
    main()
