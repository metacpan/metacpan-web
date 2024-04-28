#!/usr/bin/env node
"use strict";
import * as esbuild from 'esbuild'
import { lessLoader } from 'esbuild-plugin-less';
import fs from 'fs';
import parseArgs from 'minimist';

const config = {
    entryPoints: [
        'root/static/js/main.js',
        'root/static/less/style.less',
    ],
    assetNames: '[name]-[hash]',
    entryNames: '[name]-[hash]',
    outdir: 'root/assets',
    bundle: true,
    sourcemap: true,
    metafile: true,
    inject: ['root/static/js/inject.js'],
    loader: {
        '.eot': 'file',
        '.svg': 'file',
        '.ttf': 'file',
        '.woff': 'file',
        '.woff2': 'file',
    },
    plugins: [
        lessLoader(),
        new class {
            name = 'metacpan-build';

            setup(build) {
                build.onResolve(
                    { filter: /^(shCore|xregexp)$/ },
                    args => ({ external: true }),
                );
                build.onResolve(
                    { filter: /^\// },
                    args => ({ external: true }),
                );
                build.onEnd(result => {
                    const metafile = result.metafile;
                    if (metafile && metafile.outputs) {
                        const files = Object.keys(metafile.outputs).sort()
                            .map(file => file.replace(/^root\/assets\//, ''));
                        fs.writeFile(
                            'root/assets/assets.json',
                            JSON.stringify(files),
                            'utf8',
                            (e) => {
                                if (e) {
                                    console.log(e);
                                }
                            }
                        );
                        console.log('assets built');
                    }
                    else {
                        console.log('asset build failure');
                    }
                });
            }
        },
    ],
};

const args = parseArgs(process.argv, {
    boolean: [
        'watch',
        'minify',
    ],
});
if (args.minify) {
    config.minify = true;
}
const ctx = await esbuild.context(config);
if (args.watch) {
    await ctx.watch();
    const sig = await new Promise(resolve => {
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
