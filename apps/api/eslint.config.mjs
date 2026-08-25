import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist/**', 'node_modules/**', 'uploads/**', 'data/**', 'coverage/**'] },
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
  {
    // scripts/ 的 Node 脚本（dev-db.mjs）：声明 Node 全局变量，避免 no-undef 误报
    files: ['scripts/**/*.mjs'],
    languageOptions: {
      globals: {
        process: 'readonly',
        console: 'readonly',
      },
    },
  },
);
