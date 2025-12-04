import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test('should navigate to the home page and display the dashboard title', async ({ page }) => {
    await page.goto('/'); // Base URL is configured in playwright.config.ts

    // Expect a title "to contain" a substring.
    await expect(page).toHaveTitle(/MATEOS V2 - Gestión Estratégica/);

    // Expect the heading to be present
    await expect(page.getByRole('heading', { name: 'Bienvenido al Dashboard Estratégico' })).toBeVisible();

    // Expect the sidebar to be visible
    await expect(page.getByRole('navigation').getByText('Dashboard')).toBeVisible();
    await expect(page.getByRole('navigation').getByText('Proyectos Estratégicos')).toBeVisible();
  });

  test('should allow toggling theme', async ({ page }) => {
    await page.goto('/');

    // Check initial theme (assuming light by default from ThemeContext)
    await expect(page.locator('html')).not.toHaveClass('dark');

    // Toggle to dark mode
    await page.getByRole('button', { name: '🌙 Dark Mode' }).click();
    await expect(page.locator('html')).toHaveClass('dark');

    // Toggle back to light mode
    await page.getByRole('button', { name: '☀️ Light Mode' }).click();
    await expect(page.locator('html')).not.toHaveClass('dark');
  });
});
