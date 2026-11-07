import { readFileSync, readdirSync, realpathSync, statSync } from 'node:fs';
import path from 'node:path';

const mime = { '.png':'image/png', '.jpg':'image/jpeg', '.jpeg':'image/jpeg', '.gif':'image/gif',
  '.webp':'image/webp', '.mp4':'video/mp4', '.webm':'video/webm' };
const type = file => mime[path.extname(file).toLowerCase()];
const maxMediaBytes = 64 * 1024 * 1024;
function data(file) {
  if (statSync(file).size > maxMediaBytes) throw Error('Wallpaper file exceeds 64 MiB.');
  return 'data:' + type(file) + ';base64,' + readFileSync(file).toString('base64');
}

function catalog(roots) {
  const items = new Map();
  for (const root of roots) {
    for (const entry of readdirSync(root, { withFileTypes:true })) {
      if (!entry.isDirectory() || !/^\d+$/.test(entry.name)) continue;
      try {
        const dir = realpathSync(path.join(root, entry.name));
        const metadata = JSON.parse(readFileSync(path.join(dir, 'project.json'), 'utf8').replace(/^\uFEFF/, ''));
        function local(name) {
          if (typeof name !== 'string' || !type(name)) return;
          try {
            const file = realpathSync(path.resolve(dir, name));
            const relative = path.relative(dir, file);
            if (relative && !relative.startsWith('..') && !path.isAbsolute(relative)) return file;
          } catch {}
        }
        const preview = [metadata.preview, 'preview.jpg', 'preview.png', 'preview.gif', 'preview.webp']
          .map(local).find(Boolean);
        const isScene = String(metadata.type).toLowerCase() === 'scene';
        const cachedStill = isScene && process.env.LOCALAPPDATA
          ? path.join(process.env.LOCALAPPDATA, 'CWAuto', 'scene-stills', entry.name + '.jpg') : null;
        const sceneStill = cachedStill && statSync(cachedStill, {throwIfNoEntry:false})?.isFile()
          ? cachedStill : null;
        const original = local(metadata.file) ?? sceneStill;
        const oversized = original && !type(original).startsWith('video/') && statSync(original).size > maxMediaBytes;
        const media = original && !oversized ? original : preview;
        if (!media) continue;
        items.set(entry.name, { id:entry.name, title:String(metadata.title || entry.name),
          preview, media, fallback:media !== original, oversized:Boolean(oversized), sceneStill:Boolean(sceneStill && media === sceneStill) });
      } catch {}
    }
  }
  return items;
}

function mount(items) {
  const key = '__codexWallpaperCleanup';
  window[key]?.();
  let dialog, background, status, glass, layoutObserver, layoutFrame;
  const mainSurface = 'data-codex-wallpaper-main-surface';
  const footerSurface = 'data-codex-wallpaper-footer';
  const sidebarGlass = 'data-codex-wallpaper-sidebar-glass';
  const composerSurface = 'data-codex-wallpaper-composer';
  function refreshMainSurfaces() {
    if (layoutFrame) return;
    layoutFrame = requestAnimationFrame(() => {
      layoutFrame = 0;
      const candidates = new Set();
      const editor = [...document.querySelectorAll('#prompt-textarea, [contenteditable="true"], textarea')]
        .find(node => {
          const rect = node.getBoundingClientRect();
          return rect.width >= 160 && rect.height > 0 && rect.top > innerHeight * .65 &&
            !node.closest('dialog, [role="dialog"]');
        });
      if (editor) {
        const editorRect = editor.getBoundingClientRect();
        let composer;
        for (let node = editor.parentElement; node && node !== document.body; node = node.parentElement) {
          const rect = node.getBoundingClientRect();
          if (rect.height >= 55 && rect.height < innerHeight * .30 &&
              rect.width <= editorRect.width + 160 &&
              parseFloat(getComputedStyle(node).borderTopLeftRadius) >= 8) composer = node;
        }
        for (const old of document.querySelectorAll('[' + composerSurface + ']')) {
          if (old !== composer) old.removeAttribute(composerSurface);
        }
        composer?.removeAttribute(footerSurface);
        composer?.setAttribute(composerSurface, '');

        // Decorative gradients can have pointer-events:none and are absent from hit tests.
        for (const node of document.querySelectorAll('div, section, footer, form, aside, main')) {
          if (node === composer || node.closest('dialog, [role="dialog"]')) continue;
          const rect = node.getBoundingClientRect();
          if (rect.top >= innerHeight * .65 && rect.top < innerHeight &&
              rect.bottom > innerHeight * .8 && rect.height > 0 &&
              rect.width >= editorRect.width * .82 &&
              rect.left <= editorRect.left + 35 && rect.right >= editorRect.right - 35) {
            node.setAttribute(footerSurface, '');
          }
        }
      }
      for (const node of document.querySelectorAll('div, header, section')) {
        if (node.closest('dialog, [role="dialog"]')) continue;
        const rect = node.getBoundingClientRect();
        if (rect.width >= innerWidth * .55 && rect.height > 0 && rect.height <= 84 &&
            rect.top >= 35 && rect.top <= innerHeight * .20) {
          node.setAttribute(footerSurface, '');
        }
      }

      let sidebar;
      for (const x of [.06, .13, .19]) {
        for (const y of [.22, .55, .86]) {
          for (let node of document.elementsFromPoint(innerWidth * x, innerHeight * y)) {
            while (node && node !== document.body && node !== document.documentElement) {
              const rect = node.getBoundingClientRect();
              if (node !== background && !node.closest('dialog, [role="dialog"]') &&
                  rect.left < innerWidth * .24 && rect.right < innerWidth * .45 &&
                  rect.width > 90 && rect.height > innerHeight * .35) {
                node.setAttribute(footerSurface, '');
                if (!sidebar || rect.width * rect.height >
                    sidebar.getBoundingClientRect().width * sidebar.getBoundingClientRect().height) sidebar = node;
              }
              node = node.parentElement;
            }
          }
        }
      }
      for (const old of document.querySelectorAll('[' + sidebarGlass + ']')) {
        if (old !== sidebar) old.removeAttribute(sidebarGlass);
      }
      sidebar?.setAttribute(sidebarGlass, '');

      for (const x of [.27, .35, .55, .75, .85, .9]) {
        for (const y of [.25, .5, .75, .83, .89, .96, .985]) {
          for (let node of document.elementsFromPoint(innerWidth * x, innerHeight * y)) {
            while (node && node !== document.body && node !== document.documentElement) {
              candidates.add(node);
              node = node.parentElement;
            }
          }
        }
      }
      for (const node of candidates) {
        if (node === background || dialog?.contains(node) || node.closest('dialog, [role="dialog"]')) continue;
        const rect = node.getBoundingClientRect();
        const isMain = rect.height >= innerHeight * .65;
        const isFooter = editor && rect.top >= innerHeight * .60 &&
          rect.top < innerHeight && rect.height <= innerHeight * .39 &&
          rect.width >= editor.getBoundingClientRect().width &&
          rect.left <= editor.getBoundingClientRect().left + 6 &&
          rect.right >= editor.getBoundingClientRect().right - 6;
        if (isFooter && !node.hasAttribute(composerSurface)) node.setAttribute(footerSurface, '');
        if (rect.width >= innerWidth * .45 && (isMain || isFooter) &&
            rect.left < innerWidth * .6 && rect.right > innerWidth * .8) {
          const color = getComputedStyle(node).backgroundColor;
          if (color !== 'transparent' && color !== 'rgba(0, 0, 0, 0)') node.setAttribute(mainSurface, '');
        }
      }
    });
  }
  function enableGlass() {
    if (glass) return;
    glass = document.createElement('style');
    glass.textContent = `
      body[data-codex-wallpaper] {
        isolation: isolate;
        text-shadow:
          0 0 1px var(--codex-wallpaper-text-halo),
          0 1px 2px var(--codex-wallpaper-text-halo),
          0 0 5px var(--codex-wallpaper-text-halo);
        --codex-wallpaper-text-halo: light-dark(rgba(255,255,255,.96), rgba(0,0,0,.98));
      }
      :is(.dark, [data-theme="dark"], [data-color-mode="dark"]) body[data-codex-wallpaper],
      body:is(.dark, [data-theme="dark"], [data-color-mode="dark"])[data-codex-wallpaper] {
        --codex-wallpaper-text-halo: rgba(0,0,0,.98);
      }
      body[data-codex-wallpaper] :is(p, li, a, button, label, textarea, [contenteditable="true"]) {
        text-shadow: inherit;
      }
      body[data-codex-wallpaper] > :is(#root, #app, [data-reactroot]) {
        position: relative;
        z-index: 1;
        background-color: transparent !important;
      }
      body[data-codex-wallpaper] :is(.bg-token-bg-primary, .bg-token-main-surface-primary, [data-codex-wallpaper-main-surface]) {
        background-color: transparent !important;
      }
      body[data-codex-wallpaper] [data-codex-wallpaper-footer],
      body[data-codex-wallpaper] [data-codex-wallpaper-footer]::before,
      body[data-codex-wallpaper] [data-codex-wallpaper-footer]::after {
        background: transparent !important;
        box-shadow: none !important;
        backdrop-filter: none !important;
      }
      body[data-codex-wallpaper] [data-codex-wallpaper-sidebar-glass],
      body[data-codex-wallpaper] [data-codex-wallpaper-composer] {
        background: rgba(255, 255, 255, .04) !important;
        backdrop-filter: blur(9px) !important;
        box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .19);
      }
      body[data-codex-wallpaper] :is(#prompt-textarea, [data-testid="composer-input"]) {
        background: transparent !important;
      }
    `;
    document.head.append(glass);
    document.body.setAttribute('data-codex-wallpaper', '');
    layoutObserver = new MutationObserver(refreshMainSurfaces);
    layoutObserver.observe(document.body, {childList:true, subtree:true});
    window.addEventListener('resize', refreshMainSurfaces);
    refreshMainSurfaces();
  }
  function disposeBackground(node) {
    if (!node) return;
    if (node instanceof HTMLVideoElement) {
      const url = node.src;
      node.pause();
      node.removeAttribute('src');
      node.load();
      if (url.startsWith('blob:')) URL.revokeObjectURL(url);
    }
    node.remove();
  }
  function removeWallpaper() {
    disposeBackground(background);
    background = null;
    glass?.remove();
    glass = null;
    layoutObserver?.disconnect();
    layoutObserver = null;
    cancelAnimationFrame(layoutFrame);
    layoutFrame = 0;
    window.removeEventListener('resize', refreshMainSurfaces);
    for (const marker of [mainSurface, footerSurface, composerSurface, sidebarGlass]) {
      for (const node of document.querySelectorAll('[' + marker + ']')) node.removeAttribute(marker);
    }
    document.body.removeAttribute('data-codex-wallpaper');
  }
  const opacityKey = 'codex-wallpaper.opacity';
  const selectionKey = 'codex-wallpaper.selection';
  const savedOpacity = localStorage.getItem(opacityKey);
  let opacity = savedOpacity !== null && /^\d{1,3}$/.test(savedOpacity)
    ? Math.min(100, Number(savedOpacity)) : 24;
  const thumbnails = new Map();
  window.__codexWallpaperThumbnail = (id, url) => {
    const image = thumbnails.get(id);
    if (image) image.src = url;
  };
  const apply = async (url, video) => {
    if (!url) {
      removeWallpaper();
      return;
    }
    let next;
    if (video) {
      next = document.createElement('video');
      Object.assign(next, {muted:true, loop:true, playsInline:true});
      let timer, onPolicyViolation;
      const loadFailure = new Promise((_, reject) => {
        timer = setTimeout(() => reject(Error('视频加载超时')), 7000);
        onPolicyViolation = event => {
          if (event.effectiveDirective === 'media-src') {
            reject(Error('Codex 的媒体策略拦截了本地视频地址 (media-src)'));
          }
        };
        document.addEventListener('securitypolicyviolation', onPolicyViolation);
      });
      try {
        next.src = url;
        await Promise.race([next.play(), loadFailure]);
      } catch (error) {
        const detail = next.error?.message || error.message;
        next.removeAttribute('src');
        next.load();
        if (url.startsWith('blob:')) URL.revokeObjectURL(url);
        throw Error(detail);
      } finally {
        clearTimeout(timer);
        document.removeEventListener('securitypolicyviolation', onPolicyViolation);
      }
    } else {
      const [header, base64] = url.split(',', 2);
      const bytes = Uint8Array.from(atob(base64), char => char.charCodeAt(0));
      const bitmap = await createImageBitmap(new Blob([bytes], {type:header.slice(5).split(';')[0]}));
      next = document.createElement('canvas');
      try {
        next.width = bitmap.width;
        next.height = bitmap.height;
        next.getContext('2d').drawImage(bitmap, 0, 0);
      } finally { bitmap.close(); }
    }
    Object.assign(next.style, {position:'fixed', inset:'0', width:'100%', height:'100%',
      objectFit:'cover', opacity:String(opacity / 100), pointerEvents:'none', zIndex:'0'});
    next.setAttribute('aria-hidden', 'true');
    enableGlass();
    document.body.prepend(next);
    disposeBackground(background);
    background = next;
  };
  window.__codexWallpaperResult = (error, selectedId) => {
    if (!error && typeof selectedId === 'string') {
      if (selectedId) localStorage.setItem(selectionKey, selectedId);
      else localStorage.removeItem(selectionKey);
    }
    if (!status) return;
    status.textContent = error || '';
    if (!error && dialog?.open) dialog.close();
  };
  window.__codexWallpaperApply = apply;
  const togglePanel = () => {
    if (dialog?.open) { dialog.close(); return; }
    if (!dialog) {
      dialog = document.createElement('dialog');
      dialog.setAttribute('aria-label', 'Wallpaper Engine');
      Object.assign(dialog.style, {width:'min(900px, 90vw)', maxHeight:'80vh', padding:'20px',
        background:'#202124', color:'white', border:'1px solid #666', borderRadius:'12px'});
      const header = document.createElement('h2');
      header.textContent = 'Wallpaper Engine';
      dialog.append(header);
      const grid = document.createElement('div');
      Object.assign(grid.style, {display:'grid', gap:'10px',
        gridTemplateColumns:'repeat(auto-fill,minmax(160px,1fr))'});
      const button = (label, action) => {
        const el = document.createElement('button');
        el.type = 'button';
        el.textContent = label;
        Object.assign(el.style, {padding:'8px', background:'#303134', color:'white', borderRadius:'6px'});
        el.onclick = () => { status.textContent = 'Applying wallpaper...'; action(); };
        return el;
      };
      status = document.createElement('p');
      status.setAttribute('role', 'status');
      const opacityLabel = document.createElement('label');
      opacityLabel.style.display = 'block';
      const opacityValue = document.createElement('span');
      opacityValue.textContent = '壁纸不透明度 ' + opacity + '% ';
      const slider = document.createElement('input');
      slider.type = 'range';
      slider.min = '0';
      slider.max = '100';
      slider.value = String(opacity);
      slider.oninput = () => {
        opacity = Number(slider.value);
        opacityValue.textContent = '壁纸不透明度 ' + opacity + '% ';
        if (background) background.style.opacity = String(opacity / 100);
      };
      slider.onchange = () => localStorage.setItem(opacityKey, String(opacity));
      opacityLabel.append(opacityValue, slider);
      dialog.append(opacityLabel, button('Restore default', () => window.codexWallpaperSelect('')), status, grid);
      for (const item of items) {
        const card = button(item.title + (item.oversized ? ' · 原文件过大' : item.fallback ? ' · 仅可预览，需场景渲染' : item.sceneStill ? ' · 高清静态' : ''),
          () => window.codexWallpaperSelect(item.id));
        card.disabled = item.fallback;
        if (item.hasPreview) {
          const img = document.createElement('img');
          thumbnails.set(item.id, img);
          img.alt = '';
          Object.assign(img.style, {display:'block', width:'100%', height:'90px', objectFit:'cover'});
          card.prepend(img);
        }
        grid.append(card);
      }
      document.body.append(dialog);
    }
    dialog.showModal();
    if (typeof window.codexWallpaperSelect !== 'function') {
      status.textContent = '壁纸服务未连接，请查看启动器。';
    } else if (!dialog.dataset.thumbnailsRequested) {
      window.codexWallpaperSelect('thumbnails');
      dialog.dataset.thumbnailsRequested = '1';
    }
  };
  const open = event => {
    if (!event.ctrlKey || !event.altKey || event.repeat ||
        (event.code !== 'KeyW' && event.key?.toLowerCase() !== 'w')) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    togglePanel();
  };
  window.addEventListener('keydown', open, true);
  const savedId = localStorage.getItem(selectionKey);
  if (savedId && items.some(item => item.id === savedId && !item.fallback)) window.codexWallpaperSelect(savedId);
  window[key] = () => {
    window.removeEventListener('keydown', open, true);
    dialog?.remove();
    removeWallpaper();
    delete window.__codexWallpaperApply;
    delete window.__codexWallpaperResult;
    delete window.__codexWallpaperThumbnail;
    delete window.__codexWallpaperChunks;
  };
}

const [port, ...roots] = process.argv.slice(2);
const items = catalog(roots);
if (port === '--list') {
  console.log(JSON.stringify([...items.values()], null, 2));
} else {
  const endpoint = 'http://127.0.0.1:' + port;
  const version = await (await fetch(endpoint + '/json/version', {redirect:'error'})).json();
  const address = new URL(version.webSocketDebuggerUrl);
  if (address.protocol !== 'ws:' || address.hostname !== '127.0.0.1' || address.port !== port) {
    throw Error('Unexpected debugger address.');
  }
  const ws = new WebSocket(address);
  await new Promise((resolve, reject) => {
    ws.addEventListener('open', resolve, {once:true});
    ws.addEventListener('error', reject, {once:true});
  });
  const disconnected = new Promise(resolve => {
    ws.addEventListener('close', resolve, {once:true});
  });
  let serial = 0;
  const pending = new Map();
  function send(method, params = {}, sessionId) {
    const id = ++serial;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => { pending.delete(id); reject(Error(method + ' timed out')); }, 15000);
      pending.set(id, message => {
        clearTimeout(timer);
        if (message.error || message.result?.exceptionDetails) reject(Error(message.result?.exceptionDetails?.exception?.description || message.error?.message || message.result?.exceptionDetails?.text || method));
        else resolve(message.result);
      });
      ws.send(JSON.stringify({id, method, params, sessionId}));
    });
  }
  ws.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    if (!message.id) return;
    pending.get(message.id)?.(message);
    pending.delete(message.id);
  });

  async function mountTarget(target) {
    const {sessionId} = await send('Target.attachToTarget', {targetId:target.targetId, flatten:true});
    let detach;
    const detached = new Promise(resolve => { detach = resolve; });
    const evaluate = expression => send('Runtime.evaluate', {expression, awaitPromise:true}, sessionId);
    async function playLocalVideo(file) {
      const input = await evaluate(`(() => {
        const field = document.createElement('input');
        field.type = 'file';
        return field;
      })()`);
      const objectId = input.result.objectId;
      if (!objectId) throw Error('无法创建本地视频文件句柄。');
      try {
        await send('DOM.setFileInputFiles', {objectId, files:[file]}, sessionId);
        await send('Runtime.callFunctionOn', {
          objectId, awaitPromise:true,
          functionDeclaration: `async function () {
            const file = this.files[0];
            if (!file) throw Error('无法读取选中的本地视频文件。');
            await window.__codexWallpaperApply(URL.createObjectURL(file), true);
          }`,
        }, sessionId);
      } finally {
        await send('Runtime.releaseObject', {objectId}, sessionId).catch(() => {});
      }
    }
    async function transfer(url, applyExpression) {
      if (!url) return evaluate(applyExpression('""'));
      await evaluate('window.__codexWallpaperChunks = []; void 0');
      try {
        for (let offset = 0; offset < url.length; offset += 32768) {
          const chunk = JSON.stringify(url.slice(offset, offset + 32768));
          await evaluate('void window.__codexWallpaperChunks.push(' + chunk + ')');
        }
        await evaluate(applyExpression('window.__codexWallpaperChunks.join("")'));
      } finally {
        await evaluate('delete window.__codexWallpaperChunks').catch(() => {});
      }
    }
    let selection = Promise.resolve();
    let thumbnailLoad = Promise.resolve();
    const onMessage = event => {
      const message = JSON.parse(event.data);
      if (message.method === 'Target.detachedFromTarget' && message.params.sessionId === sessionId) {
        detach();
      } else if (message.sessionId === sessionId && message.method === 'Runtime.bindingCalled' &&
          message.params.name === 'codexWallpaperSelect') {
        const id = message.params.payload;
        if (id === 'thumbnails') {
          thumbnailLoad = thumbnailLoad.then(async () => {
            for (const item of items.values()) {
              if (!item.preview) continue;
              selection = selection.then(() => transfer(data(item.preview), url =>
                'window.__codexWallpaperThumbnail?.(' + JSON.stringify(item.id) + ',' + url + ')'))
                .catch(error => console.error('Thumbnail: ' + error.message));
              await selection;
            }
          });
          return;
        }
        selection = selection.then(async () => {
          const item = items.get(id);
          if (id && !item) return;
          if (item?.fallback) return;
          if (item && type(item.media).startsWith('video/')) {
            await playLocalVideo(item.media);
          } else {
            await transfer(item ? data(item.media) : '', value =>
              'window.__codexWallpaperApply(' + value + ',false)');
          }
          await evaluate('window.__codexWallpaperResult?.("",' + JSON.stringify(id) + ')');
        }).catch(async error => {
          const detail = error.message.slice(0, 900);
          console.error('Original wallpaper failed: ' + detail);
          await evaluate('window.__codexWallpaperResult?.(' +
            JSON.stringify('原壁纸加载失败：' + detail) + ')')
            .catch(() => {});
        });
      }
    };
    ws.addEventListener('message', onMessage);
    try {
      await send('Runtime.enable', {}, sessionId);
      await send('Runtime.addBinding', {name:'codexWallpaperSelect'}, sessionId);
      const display = [...items.values()].map(({id,title,preview,fallback,oversized,sceneStill}) =>
        ({id,title,hasPreview:Boolean(preview),fallback,oversized,sceneStill}));
      const install = '(' + mount.toString() + ')(' + JSON.stringify(display) + ')';
      const source = 'document.body ? ' + install + ' : document.addEventListener("DOMContentLoaded", () => {' +
        install + '}, {once:true})';
      await send('Page.addScriptToEvaluateOnNewDocument', {source}, sessionId);
      await evaluate(source);
      console.log('Connected to Codex renderer ' + target.targetId + '. Press Ctrl+Alt+W in Codex.');
      await Promise.race([detached, disconnected]);
    } finally {
      ws.removeEventListener('message', onMessage);
      if (ws.readyState === WebSocket.OPEN) {
        await send('Target.detachFromTarget', {sessionId}).catch(() => {});
      }
    }
  }

  try {
    while (ws.readyState === WebSocket.OPEN) {
      const {targetInfos} = await send('Target.getTargets');
      const target = targetInfos.find(t => typeof t.targetId === 'string' && t.type === 'page' && /^app:\/\//.test(t.url));
      if (target) {
        try { await mountTarget(target); }
        catch (error) { console.error('Could not attach to Codex renderer: ' + error.message); }
      }
      if (ws.readyState === WebSocket.OPEN) await new Promise(resolve => setTimeout(resolve, 1000));
    }
    const event = await disconnected;
    console.error('Disconnected from Codex browser (WebSocket code ' + event.code + ').');
    if (event.code === 1006 || event.code === 1001) process.exitCode = 75;
  } catch (error) {
    ws.close();
    throw error;
  }
}




