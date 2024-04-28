#!/usr/bin/env node
"use strict";
import * as esbuild from 'esbuild'
import { lessLoader } from 'esbuild-plugin-less';
import { writeFile, opendir, unlink } from 'node:fs/promises';
import path from 'node:path';
import parseArgs from 'minimist';

const assets_dir = 'root/assets';

const config = {
    entryPoints: [
        'root/static/js/main.js',
        'root/static/less/style.less',
    ],
    assetNames: '[name]-[hash]',
    entryNames: '[name]-[hash]',
    outdir: assets_dir,
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
                build.onStart(() => {
                    console.log('building assets...')
                });
                build.onResolve(
                    { filter: /^(shCore|xregexp)$/ },
                    args => ({ external: true }),
                );
                build.onResolve(
                    { filter: /^\// },
                    args => ({ external: true }),
                );
                build.onEnd(async result => {
                    const metafile = result.metafile;
                    if (metafile && metafile.outputs) {
                        const files = Object.keys(metafile.outputs).sort()
                            .map(file => path.relative(assets_dir, file));
                        try {
                            await writeFile(
                                path.join(assets_dir, 'assets.json'),
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
        },
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

    for await (const file of await opendir(assets_dir, { withFileTypes: true })) {
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
