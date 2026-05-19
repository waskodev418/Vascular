const urlComponents = "../components/";

async function router() {
    const container = document.getElementById('app-root');
    
    const hash = window.location.hash.substring(1) || 'login';
    history.replaceState(null, "", window.location.pathname);
    const parts = hash.split('/');
    const componentName = parts[parts.length - 1];

    //File-based Routing per un caricamento piu' dinamico e scalabile
    const componentPath = urlComponents + hash + "/" + componentName + ".js";

    try {
        const module = await import(componentPath);
        
        const page = new module.default('app-root');
             
        await page.render();

    } catch (error) {
        console.error("Errore nel caricamento del componente -> ", error);
        container.innerHTML = `<div class="error">Impossibile caricare il modulo: ${hash}</div>`;
    }
}

window.addEventListener('hashchange', router);

window.addEventListener('load', router);