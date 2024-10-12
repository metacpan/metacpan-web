#!/usr/bin/env node

import * as esbuild from 'esbuild';
import { lessLoader } from 'esbuild-plugin-less';
import {
    writeFile,
    opendir,
    unlink,
} from 'node:fs/promises';
import console from 'node:console';
import process from 'node:process';
import path from 'node:path';
import parseArgs from 'minimist';

const config = {
    entryPoints: [
        'root/static/js/main.mjs',
        'root/static/less/style.less',
    ],
    assetNames: '[name]-[hash]',
    entryNames: '[name]-[hash]',
    format:     'esm',
    outdir:     'root/assets',
    bundle:     true,
    sourcemap:  true,
    inject:     ['root/static/js/inject.mjs'],
    loader:     {
        '.eot':   'file',
        '.svg':   'file',
        '.ttf':   'file',
        '.woff':  'file',
        '.woff2': 'file',
    },
    plugins: [
        lessLoader(),
        new class {
            name = 'metacpan-build';

            setup(build) {
                build.onResolve({
                    filter: /^\//,
                },
                () => ({
                    external: true,
                }),
                );

                build.initialOptions.metafile = true;
                build.onStart(() => {
                    console.log('building assets...');
                });
                build.onEnd(async (result) => {
                    const outputs = result?.metafile?.outputs;
                    if (outputs) {
                        const files = Object.keys(outputs).sort()
                            .map(file => path.relative(build.initialOptions.outdir, file));
                        try {
                            await writeFile(
                                path.join(build.initialOptions.outdir, 'assets.json'),
                                JSON.stringify(files),
                                'utf8',
                            );
                        }
                        catch (e) {
                            console.log(e);
                        }
                        console.log(`build complete (${files.filter(f => !f.match(/\.map$/)).join(' ')})`);
                    }
                });
            }
        }(),
    ],
};

const args = parseArgs(process.argv, {
    boolean: [
        'watch',
        'minify',
        'clean',
    ],
});
if (args.minify) {
    config.minify = true;
}
if (args.clean) {
    for await (const file of await opendir(config.outdir, {
        withFileTypes: true,
    })) {
        const filePath = path.join(file.parentPath, file.name);
        if (file.name.match(/^\./)) {
            // ignore these
        }
        else if (!file.isFile()) {
            console.log(`cowardly refusing to remove non-file ${filePath}`);
        }
        else {
            console.log(`deleting ${filePath}`);
            await unlink(filePath);
        }
    }
}

const ctx = await esbuild.context(config);
if (args.watch) {
    await ctx.watch();
    const sig = await new Promise((resolve) => {
        [
            'SIGTERM',
            'SIGQUIT',
            'SIGINT',
        ].map(sig => process.on(sig, resolve));
    });
    process.stderr.write(`Caught signal: ${sig}\n`);
    ctx.dispose();
}
else {
    await ctx.rebuild();
    ctx.dispose();
}
