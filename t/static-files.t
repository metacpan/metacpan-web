use strict;
use warnings;

use Test::More;
use Digest::SHA ();

# This test validates that all of the static files in the images, icons, and
# fonts directories have the expected content. These files are served with an
# infinite cache time, their content should never change in any meaningful
# way. If the content of one of these files needs to change, it should
# normally use a new file name. If it's a minor change where it is acceptable
# for users to use the old files, then updating the hash can be done instead.

my %files = (
    'root/static/fonts/FontAwesome.otf' =>
        '6270a4a561a69fef5f5cc18cdf9efc256ec2ccbe',
    'root/static/fonts/fa-brands-400.eot' =>
        '7ed86fe71d4dc31d5edf492f7472d6fb88c3c3c9',
    'root/static/fonts/fa-brands-400.svg' =>
        '3e9abaae5dc647f4019a4dcdde1b51f14c2054e8',
    'root/static/fonts/fa-brands-400.ttf' =>
        'c5a1a93f668d15f55deac38b4728f8d901bd4748',
    'root/static/fonts/fa-brands-400.woff' =>
        '6900998c1d878e73b2f9ac3a9a9746365d49a54f',
    'root/static/fonts/fa-brands-400.woff2' =>
        '5fe986cda635681b4b6bbd6111df2f26d7fca286',
    'root/static/fonts/fa-regular-400.eot' =>
        '1115185386ada5846eecc4e2e1f076ca7617e0cd',
    'root/static/fonts/fa-regular-400.svg' =>
        'dd1b42f8776d9b48adda30b0069aa0e5f18989d3',
    'root/static/fonts/fa-regular-400.ttf' =>
        '5d5375ce3ae5b500df039da009ccdaca29d52fc0',
    'root/static/fonts/fa-regular-400.woff' =>
        '7626840dab0e2ae37b2d16572a6f183a71a0dd73',
    'root/static/fonts/fa-regular-400.woff2' =>
        'be142af0f56062f6e864de121b98054c7b5954fd',
    'root/static/fonts/fa-solid-900.eot' =>
        '340ee70e87850176047733192ea8109dd6380082',
    'root/static/fonts/fa-solid-900.svg' =>
        '55a9f6dd285c88c6c9847fee0d5ce127c4c61c52',
    'root/static/fonts/fa-solid-900.ttf' =>
        '40d9789010f6137e543e4d97025b867707d2f425',
    'root/static/fonts/fa-solid-900.woff' =>
        '43dae5c2482bfb5d04d896529600eb621181103a',
    'root/static/fonts/fa-solid-900.woff2' =>
        'b2879f9e1d0985a96842bf7f55a2b2cc4c636d04',
    'root/static/fonts/fontawesome-webfont.eot' =>
        '0183979056f0b87616cd99d5c54a48f3b771eee6',
    'root/static/fonts/fontawesome-webfont.svg' =>
        'cd980eab6db5fa57db670cb2e4278e67e1a4d6c9',
    'root/static/fonts/fontawesome-webfont.ttf' =>
        '6225ccc4ec94d060f19efab97ca42d842845b949',
    'root/static/fonts/fontawesome-webfont.woff' =>
        '7d65e0227d0d7cdc1718119cd2a7dce0638f151c',
    'root/static/icons/apple-touch-icon.png' =>
        'b0697c267731b7ee53e8e7a3bbd9f6476c0ba29a',
    'root/static/icons/asc.gif' => '05fa1fbc4b6541c3e8176d235766fa0e411e9931',
    'root/static/icons/bg.gif'  => '307311e1752fa2c8dc63c91c684f2f1db3bc0a98',
    'root/static/icons/box.png' => 'f423bac33e39d81888cdf716b988a3200e5dba8b',
    'root/static/icons/busy.gif' =>
        'f28f919102d9971f6f433465b37d3213f16f7c52',
    'root/static/icons/desc.gif' =>
        '4177aef38e79be4088aca7350ef215cc053c3c9a',
    'root/static/icons/favicon-16.ico' =>
        '9352147a2cb97acb161f21202e9bfec29b6faa30',
    'root/static/icons/favicon.ico' =>
        '2ef4ad41df53e9361604fc7e110d28949e972b8f',
    'root/static/icons/folder.png' =>
        '0a32f6efba1dd71fd2250e2de12261948c4316a8',
    'root/static/icons/grid.png' =>
        'a7f7eaa459a8decc892ad92e5e3a376b0f3d568f',
    'root/static/icons/icon-rss.png' =>
        '2a9659e15773869426894fe38acff4b797e17b65',
    'root/static/icons/metacpan-icon.png' =>
        '1b893940fe0107f9e9da5c50a40320c26f25774a',
    'root/static/icons/metacpan-icon-large.png' =>
        'b0697c267731b7ee53e8e7a3bbd9f6476c0ba29a',
    'root/static/icons/package.png' =>
        'cbb30244c85540bedd8761b1394cb5162c98c6b6',
    'root/static/icons/page_white.png' =>
        'aa842d887b715e457517c3a6d5006189275e12fd',
    'root/static/icons/page_white_c.png' =>
        '99fff2092bff6da46ee47f0532de09c21bc821c4',
    'root/static/icons/page_white_code.png' =>
        'ca4e1d75b1288f162d5a99243fe031c96442f541',
    'root/static/icons/rss_feed.png' =>
        '11766cf1b41df71b6051824a94485f91a2283cff',
    'root/static/icons/server.png' =>
        '4d4c0a13206474e65e616e42c7505c6357d63030',
    'root/static/icons/settings.png' =>
        '93115fa16327db30c2fb7b7d580dd6c9499f82f5',
    'root/static/images/flag/ad.png' =>
        'e911cb9d9a42de8fb6e5b32000d706e0dfd15e0d',
    'root/static/images/flag/ae.png' =>
        '39538335bae98862327e5f0f2fb01417b7a917e4',
    'root/static/images/flag/af.png' =>
        '5b307e408905ffa3e3ea4544192f0530408c05aa',
    'root/static/images/flag/ag.png' =>
        '1a85e66186b9ba2b9fa4513e125ab8433802680f',
    'root/static/images/flag/ai.png' =>
        '6d0d3aa711e0fc67965771301ba40daba963047c',
    'root/static/images/flag/al.png' =>
        '98d08f282b0ad09de99d5bb46fdf239ada3f1803',
    'root/static/images/flag/am.png' =>
        'b8f6f60729242aabf0713f9202f508859e88ba38',
    'root/static/images/flag/an.png' =>
        '7a5893399cf9620a40796dda067ed38bf417a991',
    'root/static/images/flag/ao.png' =>
        'd1c3b3b2daf5d6b7b2d28c6d6ef0ec853d526dcc',
    'root/static/images/flag/ar.png' =>
        '9dca235e23e08eefda6961f75b013aa842cfefab',
    'root/static/images/flag/as.png' =>
        'b92a1e33457042ef85a7fe5d8b664144edab5fb9',
    'root/static/images/flag/at.png' =>
        'd1db90067b0ef65f154ee98c3b519d94a96b2a86',
    'root/static/images/flag/au.png' =>
        '0a429d27ec29a89a73ffaa2417a46e9891272073',
    'root/static/images/flag/aw.png' =>
        '482b104bb581f924d3c791db353a6191ee3ff213',
    'root/static/images/flag/ax.png' =>
        '95583809efd2067fec7f17088879747a614f8d4c',
    'root/static/images/flag/az.png' =>
        'e27724a4b1e0fdbeb0b0cd665929f484957f185c',
    'root/static/images/flag/ba.png' =>
        '784749e3a74a23d7d727b784d38014f85023b360',
    'root/static/images/flag/bb.png' =>
        '95f3ab56924277772631be80050038cdb86623d9',
    'root/static/images/flag/bd.png' =>
        '9706183c65453b65742fd8186c4b5b6ffb30a3b6',
    'root/static/images/flag/be.png' =>
        '00d39a4b367f56e5fab21ce6c9ba80c6bafecac4',
    'root/static/images/flag/bf.png' =>
        'f330216d23edc0c8a17496a18d3096625a2ebea7',
    'root/static/images/flag/bg.png' =>
        '5eae79249a224ab3ed1b3aeafae2e5e4099b3d37',
    'root/static/images/flag/bh.png' =>
        '3d9d74c3f627fceeb3fee278ee597ca3e7ffb049',
    'root/static/images/flag/bi.png' =>
        '2b1ed31abd59f973d7afc3e2591959a40b0067ad',
    'root/static/images/flag/bj.png' =>
        '28b63102ea24b59ea7a80eb5600da5d4a970123f',
    'root/static/images/flag/bm.png' =>
        '697ad5b4f9bc22bcea267e0d7a627c801dcbdac3',
    'root/static/images/flag/bn.png' =>
        '4b4b9ec1c7174ed64890f3adf9bd79a5aef7171d',
    'root/static/images/flag/bo.png' =>
        '1a3e81e40fd68d08a742ee4968824248e0632708',
    'root/static/images/flag/br.png' =>
        'a2cf9dbf05d87704f99045accf0d08e1425fb32f',
    'root/static/images/flag/bs.png' =>
        'ba0fd8d1e2d15a48e31d7375a626c5f5f79d6461',
    'root/static/images/flag/bt.png' =>
        'b72990713eea108215446f35c821cbd9a7b3be8f',
    'root/static/images/flag/bv.png' =>
        '2f9fe5a2a67940137caf58f8002133b18ee31f2a',
    'root/static/images/flag/bw.png' =>
        '281f414c3008840fbcc1f7b6e7c357499d6a83fc',
    'root/static/images/flag/by.png' =>
        '6d3de005757093466320d64cb5a3b54a027865b6',
    'root/static/images/flag/bz.png' =>
        '477a70be7b8a5869b64cbc75df17f55ad6f736ff',
    'root/static/images/flag/ca.png' =>
        '26ec0544aa2c524130b5d96795e739e9596304d2',
    'root/static/images/flag/catalonia.png' =>
        '3397f24cb7c8d84081c1f1d3122b5b90ebe866c9',
    'root/static/images/flag/cc.png' =>
        '6e7351c214679bc4e2b6f4f62f2352c2cb0c8e39',
    'root/static/images/flag/cd.png' =>
        'fe80616d2455fcfcc13f975171f792ca973a5616',
    'root/static/images/flag/cf.png' =>
        '4d76d63b0a09c37b02f201f5e4b3ba21795cf012',
    'root/static/images/flag/cg.png' =>
        '7995e34f7dfba4ca7b47d1d015a97338bf37e94b',
    'root/static/images/flag/ch.png' =>
        'ffecd34cb512b36341bd6c9683baa33c4deec3c9',
    'root/static/images/flag/ci.png' =>
        'f43df8f9bd028e3a6dd83f9cc8e47e98599892d8',
    'root/static/images/flag/ck.png' =>
        'd2c9a622bf8e1beca16464c2eaaa4e5d5a09e8d0',
    'root/static/images/flag/cl.png' =>
        '994cfce1d1f083d3b46a666286c614f59320ff21',
    'root/static/images/flag/cm.png' =>
        'e74bfb0bdf4fa4656bf1cbec9b34ceb23f8b369f',
    'root/static/images/flag/cn.png' =>
        '365bd1659bbcafdc82f35dcb001d3c0df0a83958',
    'root/static/images/flag/co.png' =>
        '6e691ea9d54ef2c32902bec2a28b71487d900362',
    'root/static/images/flag/cr.png' =>
        '4e4e66d500c55c4fd8e60756b7963558669d8856',
    'root/static/images/flag/cs.png' =>
        'b74d80e2c9f14c0c6c0be367edb790b2f947afed',
    'root/static/images/flag/ct.png' =>
        '3397f24cb7c8d84081c1f1d3122b5b90ebe866c9',
    'root/static/images/flag/cu.png' =>
        '6942ad8099b6a817ff9e4ec0deb868c44e6798c0',
    'root/static/images/flag/cv.png' =>
        '73e19e3328f5d5a577bc9e8ffea164487dfb2a5b',
    'root/static/images/flag/cx.png' =>
        '4cb5ed68bce93854f764936e2fe0e46c1a767b03',
    'root/static/images/flag/cy.png' =>
        '50da1a464b09a41defb32f03f5682f2f3f9d0d33',
    'root/static/images/flag/cz.png' =>
        'f4bc80d7669437587afdba1ea3ef808fdf0ccc3d',
    'root/static/images/flag/de.png' =>
        '2a6881281c20c770cc51fd8fad6b5dfc844f52e4',
    'root/static/images/flag/dj.png' =>
        '48e2520333dbd16bbe8cc4974cb27ddd375f0c52',
    'root/static/images/flag/dk.png' =>
        '4481b6addbfb1bd12531393b77aa059309888a86',
    'root/static/images/flag/dm.png' =>
        '7ddbb134472e983d6a9ae7aaa8e32e3d41e49987',
    'root/static/images/flag/do.png' =>
        'ce7b1e3a753f5c77f7c333527dbd598e4306476c',
    'root/static/images/flag/dz.png' =>
        '2e29e0d502bd9c88480e2d4fe5cadb0b9105e7c2',
    'root/static/images/flag/ec.png' =>
        '32999427d28f16c8d25c039aa753011c51ddd281',
    'root/static/images/flag/ee.png' =>
        'fc7192549dd41d7bceb120dc861c3d556fbf2b7a',
    'root/static/images/flag/eg.png' =>
        'dcc17424d9e7e321d6c1cbe0919604382e05ee51',
    'root/static/images/flag/eh.png' =>
        '8b2e0eb4f09e504949821535843cc957345c012c',
    'root/static/images/flag/england.png' =>
        '5245d907ee053876ac6b89a6b69cb36954f5029a',
    'root/static/images/flag/er.png' =>
        'ff8d1604f15900ee91e09ef6aee4b5589afe8ac6',
    'root/static/images/flag/es.png' =>
        '1277ea7d0884edd79781bdb4e5106e31cff1496b',
    'root/static/images/flag/et.png' =>
        'ef0188e3ab693b9afa0da41b1b107049f68af751',
    'root/static/images/flag/europeanunion.png' =>
        'c1b4ef64acf5d642bf04f8f04c15060aee19612d',
    'root/static/images/flag/fam.png' =>
        '75c15561ee643c386b772d9e28c5f6870ffc423b',
    'root/static/images/flag/fi.png' =>
        '064c6be220a1dcb2f9283e40dac327b35d0d02a8',
    'root/static/images/flag/fj.png' =>
        'cee28895318c27913ff7eec18aa02180b5e2a2d3',
    'root/static/images/flag/fk.png' =>
        '101462372662d05d2cc95241f0e5ad6641e64763',
    'root/static/images/flag/fm.png' =>
        '75cb037deec281fc4c42b4973f4f1b69e55966e3',
    'root/static/images/flag/fo.png' =>
        'f58bc026677f29fcff5d5f5d2fe733317368617a',
    'root/static/images/flag/fr.png' =>
        '4159c808e0bd65eae8c05cc6935f01905b7ce381',
    'root/static/images/flag/ga.png' =>
        '4e17d505b8f50cf4da8c36449258692cedf7c296',
    'root/static/images/flag/gb.png' =>
        '9f148c20a0fbd028623bcebae3c9a7fabff120e0',
    'root/static/images/flag/gd.png' =>
        '4617d801f7a8566ef087e13be5ed50d2a19d8ac3',
    'root/static/images/flag/ge.png' =>
        '00bbbc4d6c8fd24b9e8ff781845484ab176e6765',
    'root/static/images/flag/gf.png' =>
        '4159c808e0bd65eae8c05cc6935f01905b7ce381',
    'root/static/images/flag/gh.png' =>
        'f6cb942939dfd4e4cd320256718a8ff1d64d2ecc',
    'root/static/images/flag/gi.png' =>
        '080c054260c729d10bda2c4f0b725cdd7a2cbf14',
    'root/static/images/flag/gl.png' =>
        'b1e28fd662a53611a5e2f63fe7eb75beb0899540',
    'root/static/images/flag/gm.png' =>
        'f26f66c38d43040c6111d5b4c2efdbd277a56407',
    'root/static/images/flag/gn.png' =>
        '903e08874f13d9001e2bcd34eec5c01bad9cb82b',
    'root/static/images/flag/gp.png' =>
        '79d2dec35ffc2d61c3e804d8d63e0b94227d2e7b',
    'root/static/images/flag/gq.png' =>
        'b7ddbce0cd73d35129df6127be755c76f36b8620',
    'root/static/images/flag/gr.png' =>
        '675e6a2cbe99adfa941935afe2c9d89419387ace',
    'root/static/images/flag/gs.png' =>
        'e7da3ae3012cd741a7ed2df651c859c72286960d',
    'root/static/images/flag/gt.png' =>
        '723082c03f7f7428819f244fba317351fde9fe3a',
    'root/static/images/flag/gu.png' =>
        '64891149c599ab8360ba98e6ce31ec862f7b44b1',
    'root/static/images/flag/gw.png' =>
        'c8ad782350f41e18d2688d3878b062fe059df869',
    'root/static/images/flag/gy.png' =>
        '7989f78ee1aa0f196096a3e3591e6e4b59f43b63',
    'root/static/images/flag/hk.png' =>
        'b4c472e257902d3f174f6c7450bf19eb67926bc7',
    'root/static/images/flag/hm.png' =>
        '0a429d27ec29a89a73ffaa2417a46e9891272073',
    'root/static/images/flag/hn.png' =>
        '81c66133f8bb5629c22a55c33d1474fb4f415761',
    'root/static/images/flag/hr.png' =>
        'aa3d7a18af1a4a03be0f5ff67d0f017884bcc98f',
    'root/static/images/flag/ht.png' =>
        '8381b5ba9c0e061f90fa612ba06ee3c51c0cf62e',
    'root/static/images/flag/hu.png' =>
        '82aec320836283467b6e0dc3d7c0ea4a4854413e',
    'root/static/images/flag/id.png' =>
        '1cf5af73d8edeeec91c97d5bfc47380c72e52f23',
    'root/static/images/flag/ie.png' =>
        '43d06b937560bdb9279baa4ab10273f8266d302b',
    'root/static/images/flag/il.png' =>
        'e39e5ea8bd204cc57cc404ce45a2d04202b299e4',
    'root/static/images/flag/in.png' =>
        '6ae23391df19b943483983dcd669828b8fcbb2a9',
    'root/static/images/flag/io.png' =>
        '8a1eb8b224579be78eb02c7e1f9eec3f9b928ce3',
    'root/static/images/flag/iq.png' =>
        '27dbc875df93dc22d6aa2c347bcb13f213bf2643',
    'root/static/images/flag/ir.png' =>
        'c41900aba16df2c556a38aa2db2a6ce9c7a39f4f',
    'root/static/images/flag/is.png' =>
        'a31edf28c41d73435ed10e755b88f7724c911be1',
    'root/static/images/flag/it.png' =>
        '94d0ebb1aeccf465f1a5c64ab45beca7484210ca',
    'root/static/images/flag/jm.png' =>
        '6734a4afd7dbf66da9e78ad205108237c36dbfa4',
    'root/static/images/flag/jo.png' =>
        'e9f3339a3e94dcd850d31b5279e403e21b07889f',
    'root/static/images/flag/jp.png' =>
        'b48dd756851dde20d12c407002bd9c4f58ed4bee',
    'root/static/images/flag/ke.png' =>
        'f753dc44cc9bd23d499789baa99e1ac4cabfb6b6',
    'root/static/images/flag/kg.png' =>
        '5162acc630cf6b659a2ab2289a3a876647213ca7',
    'root/static/images/flag/kh.png' =>
        '02cda928fc3ee45ae892458916782c2e07c99028',
    'root/static/images/flag/ki.png' =>
        '7bdadfcf8217c89df47074866ca910c913dd2b52',
    'root/static/images/flag/km.png' =>
        '9817f10164c8cde1e4437c3760392913a09e52fb',
    'root/static/images/flag/kn.png' =>
        '69accb446ec1c0c72c9863309578df19a7e8298e',
    'root/static/images/flag/kp.png' =>
        '20673bdadf114fde3868a5c7c396c969eacbadf9',
    'root/static/images/flag/kr.png' =>
        'b0f1a94a466df6b9b53bb762a851fb76c76c4a6d',
    'root/static/images/flag/kw.png' =>
        'fab0aa5bce9c9f2215ad22a2b69d085188c9c6c3',
    'root/static/images/flag/ky.png' =>
        '979ffe300320a609f4b89f00cc58e29e62564d17',
    'root/static/images/flag/kz.png' =>
        '793297d5e1fef872122b40db3d009f56ae29e251',
    'root/static/images/flag/la.png' =>
        '1c8fb86b23cced071c7964c709a403af72106838',
    'root/static/images/flag/lb.png' =>
        'f7eab413b8ffd97f38e9d7d347c60b828db7b182',
    'root/static/images/flag/lc.png' =>
        '5eaf01dd0387e1ef768f55f537d9c0491be4c23c',
    'root/static/images/flag/li.png' =>
        '721637e46bdf66e70c4314790bc9cd02bc0e4b5e',
    'root/static/images/flag/lk.png' =>
        '3511d8cf40717c7cb5ab4c71f7a942ca8e24db34',
    'root/static/images/flag/lr.png' =>
        '54df7d1abbf8d8d4f317916dc3fec13cc96f3a16',
    'root/static/images/flag/ls.png' =>
        '6bd2e72d9a0d554798fb1ba43abbe64cb10cc80e',
    'root/static/images/flag/lt.png' =>
        '70b2c8fe0a75990c597ff9c3a32185c31de5c401',
    'root/static/images/flag/lu.png' =>
        '5af2f0378be0e00e697fe7b85a4724ebb25147da',
    'root/static/images/flag/lv.png' =>
        '9c6c095abef99834dd45f4483c5124d186327ee1',
    'root/static/images/flag/ly.png' =>
        'c091fb5623ce3c7a5121b48038131ec59c978343',
    'root/static/images/flag/ma.png' =>
        '22ee88eec9f3a1c854d306424469f761ff18072d',
    'root/static/images/flag/mc.png' =>
        '2f6486c55b91811abfccc2128b5d267ad7c5508d',
    'root/static/images/flag/md.png' =>
        'd107c091df2bc5a8d14f313b9b4e9d4a09cfd85f',
    'root/static/images/flag/me.png' =>
        'ff2e6eeb2025c6f6e691bfc575321ad26091f14a',
    'root/static/images/flag/mg.png' =>
        'dc84a1c029efef59b2547f62b28b02eadd5c6b73',
    'root/static/images/flag/mh.png' =>
        '174df935ab4a210e1ce0aa46811f4162c92cc34c',
    'root/static/images/flag/mk.png' =>
        'aa208debb1dcb2334f1ff773c554085b9c0ef298',
    'root/static/images/flag/ml.png' =>
        '06da4e5221f2dd8294e714e4ed02f1037359ff6e',
    'root/static/images/flag/mm.png' =>
        'dfa50da74c39c23c182b777a36e350230cfd8ec0',
    'root/static/images/flag/mn.png' =>
        'c2fedcfc32a483ef542b8b3c93141b851c257025',
    'root/static/images/flag/mo.png' =>
        '659cb2deb36bfc275f0acd63b5ead93f5a520ba0',
    'root/static/images/flag/mp.png' =>
        'c3eff110ae82c9fbcab6399f4221d862094db0ac',
    'root/static/images/flag/mq.png' =>
        '299aa6b9c5c6a0f554d4598c34081cb794dc427e',
    'root/static/images/flag/mr.png' =>
        '6036e30abe45df0d364ba1f25f080122b46665e5',
    'root/static/images/flag/ms.png' =>
        '06c3cc54a452f28139125a0d6aa84499c5a67872',
    'root/static/images/flag/mt.png' =>
        '3c53b90e83fcf3b5da06233f7e672e87862d0c0b',
    'root/static/images/flag/mu.png' =>
        '36ff160d256eff6487118fc6e9e34104b741df33',
    'root/static/images/flag/mv.png' =>
        '690d9e1cd9c26436b290a84a3273067713844112',
    'root/static/images/flag/mw.png' =>
        'e7a7822ebcc24e23850507869fd7fa0e2bf17e33',
    'root/static/images/flag/mx.png' =>
        '6320cb13cad2fbe0d492a49eac7c97e21f86816e',
    'root/static/images/flag/my.png' =>
        '7d06cfb6226f602329032ce34c6077ea8066fec7',
    'root/static/images/flag/mz.png' =>
        '99bd4e7b2457356a715ac1228d0acf19b6d8feee',
    'root/static/images/flag/na.png' =>
        '530fe2a2485a9078b47e669fe41aa81f051d3cd6',
    'root/static/images/flag/nc.png' =>
        '03f67268a5628f0fbaf52229ea3ea67586e868c6',
    'root/static/images/flag/ne.png' =>
        '456cbbd085faf3ec29d229167186ea3f6dc882e4',
    'root/static/images/flag/nf.png' =>
        '9b1124c29a0ab48229c90cdacf3775358945db9f',
    'root/static/images/flag/ng.png' =>
        '26a3daf83f3bf59f43b74a517fb52e01ba2bd9ac',
    'root/static/images/flag/ni.png' =>
        '8c14b7dda02c9aab049b41df4aa27ebee5e21865',
    'root/static/images/flag/nl.png' =>
        'ce1c5846aac2abed2af68974863a84949e7dae62',
    'root/static/images/flag/no.png' =>
        '2f9fe5a2a67940137caf58f8002133b18ee31f2a',
    'root/static/images/flag/np.png' =>
        '78577b348797f4c4b2b5f3f5fdfd407a93b4755f',
    'root/static/images/flag/nr.png' =>
        '4208f9ca953d4c44e33a273176efff4e204e39fe',
    'root/static/images/flag/nu.png' =>
        '0fd244ad9b38078bc4762d9d1594aee22c0cce74',
    'root/static/images/flag/nz.png' =>
        '8b061955517696287de8de68c8c15a2fe30909b5',
    'root/static/images/flag/om.png' =>
        '802389910ebae01acbee4008528bd0f13ded857c',
    'root/static/images/flag/pa.png' =>
        '4eb9c773b9a1de90fe6761930fc1650b71878128',
    'root/static/images/flag/pe.png' =>
        '051e2ea8b71b9c37a3972c5f2f622ce4e83a1e0b',
    'root/static/images/flag/pf.png' =>
        'b67e2f48aff2589df5561826f48fdcc8f14eac3d',
    'root/static/images/flag/pg.png' =>
        '1179c892b3f7fe3eaa991819a3a95127dce560eb',
    'root/static/images/flag/ph.png' =>
        '89b1b654759ab5563366f3a2642c63633ec363c5',
    'root/static/images/flag/pk.png' =>
        '7eb6ebc26684335837c4c4b56d647b087fd46bb5',
    'root/static/images/flag/pl.png' =>
        '2ea4d6d34e7a7a22fadb5d24fc45dd336d6edbb8',
    'root/static/images/flag/pm.png' =>
        'd8614baaa10ac630bb01be4a9b1cf86cbe846d27',
    'root/static/images/flag/pn.png' =>
        '81b98af7a808743cd359dd451dbd54555951ca8f',
    'root/static/images/flag/pr.png' =>
        'ae920f7c521d609322273518d9339d5addfb3c94',
    'root/static/images/flag/ps.png' =>
        '8e90096911a878844dbb375ac204e96ef31892b5',
    'root/static/images/flag/pt.png' =>
        'bb60679e5d988ec07de2226c14f136c3948048ab',
    'root/static/images/flag/pw.png' =>
        '7fd3c794af4b611d833fc622d05bbda3530e7130',
    'root/static/images/flag/py.png' =>
        'd38801ab648d2ef7ca8bc1ffeed02f0a1b6f1f10',
    'root/static/images/flag/qa.png' =>
        'd1d6b9522073684006bf6d692d9620b0949a27a9',
    'root/static/images/flag/re.png' =>
        '4159c808e0bd65eae8c05cc6935f01905b7ce381',
    'root/static/images/flag/ro.png' =>
        '736a9f0e74f44916c0731576d99fa06244a76b17',
    'root/static/images/flag/rs.png' =>
        '5d8c11c8a5b5ff90e474e3f430bfa95a448664e9',
    'root/static/images/flag/ru.png' =>
        '781c9738eb65ed1153bb9d27eb60a56bdd3d8911',
    'root/static/images/flag/rw.png' =>
        '1afe26fd7aee7efe3d6e8194dbd8dfd4e62ef2f9',
    'root/static/images/flag/sa.png' =>
        '75e0c6c4ef5fc1e4e0029baa43067463fac28f6c',
    'root/static/images/flag/sb.png' =>
        '4f5b732a2a23533d0cbf15538603219a7ebc89ea',
    'root/static/images/flag/sc.png' =>
        '2b1159c3e2a4a2102e10c6291f5dc119c9ba0cab',
    'root/static/images/flag/scotland.png' =>
        '024b77a928abbe8ae45d85a3b70627e7753d44dd',
    'root/static/images/flag/sd.png' =>
        '16688fde38bb12462f6cfe8bbe07826a51124577',
    'root/static/images/flag/se.png' =>
        '5daa2dcb4668a4022a1b47b45117e278b77fd400',
    'root/static/images/flag/sg.png' =>
        'feefe64f739aaab035b424f745cf3646722d7432',
    'root/static/images/flag/sh.png' =>
        '7db4e65f6be7b8f5151a056979376603198e0451',
    'root/static/images/flag/si.png' =>
        '6563b2a19031b91f34b824285fb35752adb1cd78',
    'root/static/images/flag/sj.png' =>
        '2f9fe5a2a67940137caf58f8002133b18ee31f2a',
    'root/static/images/flag/sk.png' =>
        'd63cd68bbbee2f97496a3f558d10456f5bc13ac9',
    'root/static/images/flag/sl.png' =>
        'cbcfbad4c341a1991ef62d87daaf585759c06190',
    'root/static/images/flag/sm.png' =>
        '8e675e11ae47508045decea9cab61a36b442574c',
    'root/static/images/flag/sn.png' =>
        '1b677e3919c9e37fcce7446cb975827a4e9c71d9',
    'root/static/images/flag/so.png' =>
        '5536648e1b25f1a943054ce0f3096d667a231fbb',
    'root/static/images/flag/sr.png' =>
        '09b84f50ad3e68729db5651504e3e6eb0fcc6aea',
    'root/static/images/flag/st.png' =>
        '5444fc4806f4493f613a9a1ad0adf7bf2a56485b',
    'root/static/images/flag/sv.png' =>
        '12a04abfd607b01b923afc8d120cc65f2869edfa',
    'root/static/images/flag/sy.png' =>
        'a01914aedf527240c5b143a07b67397a633679b5',
    'root/static/images/flag/sz.png' =>
        'f1995649de56451515b45563868f02151189ce7a',
    'root/static/images/flag/tc.png' =>
        'd4868a594bced0b24d5a062eedcb93d3efeaf90c',
    'root/static/images/flag/td.png' =>
        '988b3be29cf1a9c4eeee733082d2e14bf4b3cc66',
    'root/static/images/flag/tf.png' =>
        '4a3ab2b63a33b50d6dde32387eba39090d12492c',
    'root/static/images/flag/tg.png' =>
        'db37181efaa62e3185f8fda68e4b81b406d4223e',
    'root/static/images/flag/th.png' =>
        '8f89e069992c0b385dbf6e9db1dc30ec28042685',
    'root/static/images/flag/tj.png' =>
        '4c2242c46d32643078a92239eb4b5b9ec401b253',
    'root/static/images/flag/tk.png' =>
        '635719b49a4a1865ddd481dbdf4f1e330781eb8b',
    'root/static/images/flag/tl.png' =>
        'e6a2651119a7c9056a775074b93bdf0f29f8b668',
    'root/static/images/flag/tm.png' =>
        'eef1bf6c4e43a055da6fb6e71375a2ea7315f51b',
    'root/static/images/flag/tn.png' =>
        'd73c202e36bcb9b024011902170f17588db1380a',
    'root/static/images/flag/to.png' =>
        'cf3f7acfce003c55b27e2eddc5c64bb8846ca09b',
    'root/static/images/flag/tr.png' =>
        'baaf11e4f5e6103e11d1fc0e2261a98269a42505',
    'root/static/images/flag/tt.png' =>
        '683b179a0f643443917b0fd8952a2ec27d07efed',
    'root/static/images/flag/tv.png' =>
        '3dc4b5b82987f9989068b84112d323d31555bc5a',
    'root/static/images/flag/tw.png' =>
        '8744e67244f890b744e9f6bb178ee0cac5279438',
    'root/static/images/flag/tz.png' =>
        '108cc95d05b688df42b827f65bd4c79d98cb6713',
    'root/static/images/flag/ua.png' =>
        'e8cf9670257dd586ab8a49e91fddcd8986f6e811',
    'root/static/images/flag/ug.png' =>
        'c5bbefdf9353117a5fb398fb0bf72705c9a377c4',
    'root/static/images/flag/uk.png' =>
        'eab69d00308e3797039a6c6ea5bba3b2e16a8f09',
    'root/static/images/flag/um.png' =>
        'cd43121d7090d1e1be96f859181b22c360a76b35',
    'root/static/images/flag/us.png' =>
        '64c146a823c66cb830711c24fa7a2a42ac4de954',
    'root/static/images/flag/uy.png' =>
        '90f21f631f5cf3b52d1dcb8fff7a7081c92e9aa3',
    'root/static/images/flag/uz.png' =>
        '786d132479d93738fc3eb2e9b5d72dc7f95cd258',
    'root/static/images/flag/va.png' =>
        '4261d503e23a04c9bbc0728992475a658ae8cd25',
    'root/static/images/flag/vc.png' =>
        'ac2db6200373e22c9b08cded6d328221b2e34f38',
    'root/static/images/flag/ve.png' =>
        '31dded69754639977d86a8080ac6986eff54360a',
    'root/static/images/flag/vg.png' =>
        '0b054c34a40dc94d7c2144f47b7ec378a947e9f2',
    'root/static/images/flag/vi.png' =>
        '871c037f3a74fd5e0d426abefb254d010fd06733',
    'root/static/images/flag/vn.png' =>
        'd9b6ed835687644b66818efac5293068d00f9af8',
    'root/static/images/flag/vu.png' =>
        '4d0f005cea260e3fe5f2d04b07d65db5eefefae3',
    'root/static/images/flag/wales.png' =>
        '29cf6b6d031ab1b51b0ecba46dcb992956bd95d5',
    'root/static/images/flag/wf.png' =>
        '064b3e39dad3b20b2313f4aba50aa8c9c5e068ea',
    'root/static/images/flag/ws.png' =>
        'f6ea3e790bbe300d14785e9c2fa5b74b9261ae5f',
    'root/static/images/flag/ye.png' =>
        'e9c98327f1e5feb9598d589bf7c0810132721103',
    'root/static/images/flag/yt.png' =>
        '6ad2e72398d00b07c5bcd2f8fc40d05bf3e76cc6',
    'root/static/images/flag/za.png' =>
        'b983a95b5127f7ed81bfe3c904bd88cc399d4261',
    'root/static/images/flag/zm.png' =>
        'c3f93396b08dd00e70c3eea34c32995bb57a96a8',
    'root/static/images/flag/zw.png' =>
        '4bc2e6126a95b38933ca40389aabc5ca0d76ca03',
    'root/static/images/gray.png' =>
        '8c2ccfffd4eed6908e37032d7a73492451bb9b05',
    'root/static/images/logo.png' =>
        'd06d39e975d7292bb377e3cc9704442007d4239e',
    'root/static/images/metacpan-logo.png' =>
        'cdbe7ff70273c8950be51e7a1ce491783b5ec369',
    'root/static/images/metacpan-logo@2x.png' =>
        '645f68d19fc7c4df2587d0e6de56caf912cc8f7a',
    'root/static/images/noise.png' =>
        '726ea72bf9dffa7293fae9957dd6430dd661b6ab',
    'root/static/images/profile/bitbucket.png' =>
        '85e55afecc01c02fda7c08ea0000f3fe6c996104',
    'root/static/images/profile/blinklist.png' =>
        '59907af5778fd8082020b724a405956ef2713a5c',
    'root/static/images/profile/brightkite.png' =>
        '865636c3360bff50cd52fc34b6844e4e0e9acd74',
    'root/static/images/profile/coderwall.png' =>
        '1ccba126177dcbbdf7cc7fb24c8bb876fd3350a6',
    'root/static/images/profile/couchsurfing.png' =>
        '69344764309bcf9c9f5e873c3eda5741ec81cbfb',
    'root/static/images/profile/design_float.png' =>
        '8f46d9093cada523fb674717063cf2018d24af08',
    'root/static/images/profile/dopplr.png' =>
        '2dbed99d2f09ba268954a03b9a3425b4a14e3ef8',
    'root/static/images/profile/dotshare.png' =>
        '53456b1fe8e6f98b0d3eb6ebf8aaa165404cd417',
    'root/static/images/profile/email.png' =>
        '87d0c86253e979c396ab7e3acecc89581efd16e6',
    'root/static/images/profile/facebook.png' =>
        '65065c1a2a504cbeb4a6462ac2d3f26a0b4825da',
    'root/static/images/profile/feed.png' =>
        '7ff607f523277d6a5de3524baa9365e5c64f6fb3',
    'root/static/images/profile/flickr.png' =>
        'bb0e8cae6d057d324585aa2256d87248f232184e',
    'root/static/images/profile/friendfeed.png' =>
        '992d52f26d3d159cf2495f5a7241f67a224ea9aa',
    'root/static/images/profile/furl.png' =>
        'fcc7de7511f4d6b2dce33374cf845d1f6c0da23e',
    'root/static/images/profile/gamespot.png' =>
        '9c609efb00c434e78575dd65fb46ff100c6fbd0b',
    'root/static/images/profile/geeklist.png' =>
        '7aebb4ed3693c2fc39c17da4edbf06ad48d48d9c',
    'root/static/images/profile/github-meets-cpan.png' =>
        '82ea50c2b692fcfd63f4975cd72df684d83b28a8',
    'root/static/images/profile/github.png' =>
        'fcaac15a6ed9d86d211a46de7d450d084db31c35',
    'root/static/images/profile/gitlab.png' =>
        '844cbd9b8193fa2456cd4636a44b1251782adf1b',
    'root/static/images/profile/gitorious.png' =>
        '21dff75b978510ddfa6c33203ca8b266494ab2d0',
    'root/static/images/profile/gittip.png' =>
        'ea1e976ff12dc85fe8f3c196deff3f82b289de99',
    'root/static/images/profile/hackernews.png' =>
        'f7e6a1e78cf70e9a6ccd6b5b3eed3350fcb72b7d',
    'root/static/images/profile/hackerrank.png' =>
        '7cc60e03413a0b4000451a096e14511ca61ebb48',
    'root/static/images/profile/hackthissite.png' =>
        'b55daba74ec340398ba2264afe81c3e5e5633a7d',
    'root/static/images/profile/identica.png' =>
        'c20219860fb36018fc075e6d6ef817055fcc4100',
    'root/static/images/profile/lastfm.png' =>
        '5c8d66437824599a2a79fe1842bf739b9009e8ec',
    'root/static/images/profile/linkedin.png' =>
        'b78dd1872ced891a84456124cbc0a763f078329d',
    'root/static/images/profile/magnolia.png' =>
        '18dd9ac368cdc7d8b289aaed66aec983ccab1b28',
    'root/static/images/profile/meetup.png' =>
        'f8c660e7ddfb8d93b3d9fb91e3976ee860f5123b',
    'root/static/images/profile/metacpan.png' =>
        '1b893940fe0107f9e9da5c50a40320c26f25774a',
    'root/static/images/profile/mixx.png' =>
        'a22660e444f3059bbd0db0a5c41ce4a8cdedb1ec',
    'root/static/images/profile/myspace.png' =>
        '474cfd2775d0a86706d072649281fd4210eba917',
    'root/static/images/profile/nerdability.png' =>
        '14e8c3a7523c455e426f94ae30aeccdce84dd18b',
    'root/static/images/profile/newsblur.png' =>
        '248cde62f2b09e1972d2f2ec2d706468edc3676e',
    'root/static/images/profile/newsvine.png' =>
        '06e5135b062602d0a5bcac01b9d47b09df8fe9e6',
    'root/static/images/profile/ohloh.png' =>
        '7b734b00f54ea1f64fcb9c62c6093b2f45f0e755',
    'root/static/images/profile/perlmonks.png' =>
        'b3ef4db6f2c9e3a94103c986f93e8e6e2831f20d',
    'root/static/images/profile/pinboard.png' =>
        '6a9b7e49bdac9ba60b6c27543970c1a39c9c9bae',
    'root/static/images/profile/playperl.png' =>
        'bb259c28bd3b454ab6310e0c8f8fc2b6d93b4d51',
    'root/static/images/profile/posterous.png' =>
        '2b94126846adca0d494d86aded9d48d0b1d48018',
    'root/static/images/profile/prepan.png' =>
        '0e5490b976ed2a7bbdcc9a71dfe880ef7deca898',
    'root/static/images/profile/reddit.png' =>
        '5faff7433e8d0a0076aa6cba5852ec883b3c060d',
    'root/static/images/profile/slideshare.png' =>
        'dd0759e51cc800f84b5d8aee0de6c4e528f3600f',
    'root/static/images/profile/sourceforge.png' =>
        'fea06573ce569eb2cc44ecc562abd924c7bbcf87',
    'root/static/images/profile/speakerdeck.png' =>
        '7b2fc314fdb742b2a040931cf9b1b0bc17ca8839',
    'root/static/images/profile/sphere.png' =>
        '47b929c1a69439c75a45996f679d25e641b46bb6',
    'root/static/images/profile/sphinn.png' =>
        'a41f4f469d231b4c740dc923d28513ac9879ff25',
    'root/static/images/profile/stackexchange.png' =>
        '30e0c3ca49f528902a4328424822874e1191acd2',
    'root/static/images/profile/stackoverflow.png' =>
        '1833ddbc1bf625d3e64c2e3307bb5f5ca1edcac3',
    'root/static/images/profile/stackoverflowcareers.png' =>
        'baf53fe9e47423a0b83d1bab1247cbe8ad7cec8a',
    'root/static/images/profile/steam.png' =>
        '714f1bdbec3add94bb526d21b4ca6e175d6f7464',
    'root/static/images/profile/stumbleupon.png' =>
        '497f3c402882de7932d6ccdb76b08b32a19ae801',
    'root/static/images/profile/technorati.png' =>
        'aed08e542fba11451598925f18d08461ebac3371',
    'root/static/images/profile/tripadvisor.png' =>
        '9b7c62139ae30137cc9ce18de30b8c74e8b9c8c7',
    'root/static/images/profile/tumblr.png' =>
        'bd94b79c78da4f6edb101b5fd924280dca3ed6c7',
    'root/static/images/profile/twitter.png' =>
        '3aa31f73eb732dae56c50d36859c133c803d2ec5',
    'root/static/images/profile/vimeo.png' =>
        '9f85d80760d0a8815c2e2c1510f3d268571a98f7',
    'root/static/images/profile/youtube.png' =>
        'e4dd870616b964042c97e4ad821bb5d9035b6abf',
    'root/static/images/small_logo.png' =>
        '8019eee79d9fa1bab95e360d82551e3b7efa331a',
    'root/static/images/sponsors/activestate.png' =>
        '3c0a06c92711e067b0dcda30efce3b66af811aa0',
    'root/static/images/sponsors/advance-systems.jpg' =>
        '16b8e4557ee882a3dd157170e08d1ededa18812a',
    'root/static/images/sponsors/booking.png' =>
        'fbbdfe51514e6717796cd14bd627a49391252f93',
    'root/static/images/sponsors/bytemark_logo.png' =>
        '498ce22fc52f800891b621a1504ddea3d54fdcc9',
    'root/static/images/sponsors/control-my-id.png' =>
        'd9b2485a500502f3b648c1f01783450cb63ca2f9',
    'root/static/images/sponsors/cpanel.png' =>
        'f6b4e8fa588af67cc31c85580b71386818ca287d',
    'root/static/images/sponsors/dealspotr.png' =>
        'a6d9b6c110d6cfbdf9221bbc7b60b4d793dd6d5f',
    'root/static/images/sponsors/dyn.png' =>
        'c678847ed554215a8bd0f42d46c10cdd73c26467',
    'root/static/images/sponsors/easyname.png' =>
        '9d32914df2a28db81f435cdc44e903bb78e219a1',
    'root/static/images/sponsors/elastic.svg' =>
        '292b9ab76da7035cf192f8c651a090c4bd4bc2ab',
    'root/static/images/sponsors/epo.png' =>
        '1a34a7c495728a194fc272d3a2069df2ef90f9e0',
    'root/static/images/sponsors/fastly_logo.png' =>
        '9eac83cb298c0bd475f291dde968a820d8f54584',
    'root/static/images/sponsors/fastmail.png' =>
        'a3365d759be66a8a86dac12b3cf426a242200c03',
    'root/static/images/sponsors/github_logo.png' =>
        'ff77edb3ea13567310837717da9d2cdea155682c',
    'root/static/images/sponsors/idonethis.png' =>
        '0698d65b033849f1a368c8f68fcc01d281c9eae8',
    'root/static/images/sponsors/kritika.svg' =>
        '887d712f253b63e53319ad37cfcf3fdbd36e8a36',
    'root/static/images/sponsors/liquidweb_color.png' =>
        'b77446398da31c8785fdb20ca1349be469523f89',
    'root/static/images/sponsors/panopta.png' =>
        '7f77555505dfcb1a2c3b47bec95062fe2dd7a5da',
    'root/static/images/sponsors/perl-careers.png' =>
        'd3cebb2b17b5b5c598d5d0d5766532467fc9e7c6',
    'root/static/images/sponsors/perl-services.svg' =>
        '1eacc5aedbbaeb388801652ecc48c76fce49d530',
    'root/static/images/sponsors/perl_logo.png' =>
        '5cdd9d7bda9936c0ab678063a93df341fd37acb1',
    'root/static/images/sponsors/qah-2014.png' =>
        'e691cd3eb125c4b9e157a083a1c0a5f14e5a692a',
    'root/static/images/sponsors/servercentral.png' =>
        '0d8560e505acdbe5f13293360c9f8c371db3ce47',
    'root/static/images/sponsors/speedchilli.png' =>
        '46cf961917ca8e3e953ea8a823409f9c7fa8fe44',
    'root/static/images/sponsors/travis-ci.png' =>
        '28b210ec069326d1914b54186854e278b874e08e',
    'root/static/images/sponsors/vienna.pm.jpeg' =>
        'd1756602e3883c084a901338b96d8a03b8b540b9',
    'root/static/images/sponsors/yellowbot-small.png' =>
        '25d2fa66dcbccadd9487cd5540f9b26485b873c2',
    'root/static/images/sponsors/yellowbot.png' =>
        '6e7962a5c1467d8e5b0cd2b5901b757b8f667165',
    'root/static/images/stars-sprite-white.png' =>
        'b4287ec3dd974b466fe888f16aab7e51fe0fb421',
    'root/static/images/stars-sprite.png' =>
        '93e1f0169c9b1cca1d798b72e6226432cabc1d72',
    'root/static/images/stars-sprite@2x.png' =>
        '2020892c7f07db904aa101306712381d9d3d14c1',
    'root/static/images/t.gif' => 'eca87854262d8cb8d8be91b4f3f30aaaa323f269',
);

for my $file ( sort keys %files ) {
    my $want_sha = $files{$file};
    my $got_sha  = Digest::SHA->new('sha1')->addfile( $file, 'b' )->hexdigest;
    is $got_sha, $want_sha, "static file $file has correct content";
}

done_testing;
