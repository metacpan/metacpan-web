import globals from "globals";
import pluginJs from "@eslint/js";

export default [{
        ignores: ["root/assets/"],
    },
    {
        languageOptions: {
            globals: globals.browser,
        }
    },
    {
        files: ['build-assets.mjs'],
        languageOptions: {
            globals: globals.nodeBuiltin,
        },
    },
    {
        files: ['**/*.js'],
        languageOptions: {
            sourceType: 'commonjs',
        }
    },
    {
        files: ['**/*.mjs'],
        languageOptions: {
            sourceType: 'module',
        }
    },
    pluginJs.configs.recommended,
];
