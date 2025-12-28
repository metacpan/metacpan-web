import globals from 'globals';
import stylistic from '@stylistic/eslint-plugin';
import js from '@eslint/js';

export default [
    {
        ignores: ['root/assets/'],
    },
    {
        files:           ['**/*.mjs'],
        languageOptions: {
            sourceType: 'module',
        },
    },
    {
        files:           ['**/*.js'],
        languageOptions: {
            sourceType: 'commonjs',
        },
    },
    {
        files:           ['root/**/*.mjs', 'root/**/*.js'],
        languageOptions: {
            globals: globals.browser,
        },
    },
    js.configs.recommended,
    stylistic.configs.customize({
        semi: true,
    }),
    {
        rules: {
            '@stylistic/indent':            ['error', 4],
            '@stylistic/multiline-ternary': 'off',
            '@stylistic/key-spacing':       [
                'error',
                {
                    align: 'value',
                },
            ],
        },
    },
];
