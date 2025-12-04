import QueHacerAhoraPanel from '../components/dashboard/QueHacerAhoraPanel';
import MatarifePanel from '../components/dashboard/MatarifePanel';
import ProyectosActivosGrid from '../components/dashboard/ProyectosActivosGrid';

export default function HomePage() {
  return (
    <div className="min-h-screen p-6 bg-gray-50 dark:bg-gray-900">
      <h1 className="text-3xl font-bold mb-6 text-gray-900 dark:text-white">Bienvenido al Dashboard Estratégico</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-6">
        {/* Quick Metrics will go here */}
        {/* For now, just a placeholder */}
        <div className="p-6 bg-white rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
          <h3 className="text-lg font-semibold mb-2">Métricas Rápidas</h3>
          <p>Cargando métricas...</p>
        </div>
        <div className="p-6 bg-white rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
          <h3 className="text-lg font-semibold mb-2">Métricas Rápidas</h3>
          <p>Cargando métricas...</p>
        </div>
        <div className="p-6 bg-white rounded-lg shadow-md dark:bg-gray-800 dark:text-gray-200">
          <h3 className="text-lg font-semibold mb-2">Métricas Rápidas</h3>
          <p>Cargando métricas...</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <QueHacerAhoraPanel />
        <MatarifePanel />
      </div>

      <div className="mb-6">
        <ProyectosActivosGrid />
      </div>
    </div>
  );
}