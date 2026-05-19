class Store {
    #data = {}; 

    /**
     * Ritorna l'oggetto
     * @param {string} id chiave del oggetto
     * @returns l'oggetto
     */
    get(id) {
        return this.#data[id];
    }
   /**
     * Controlla se la chiave e' presente
     * @param {string} id chiave del oggetto
     * @returns l'oggetto
     */
    has(id) {
        return id in this.#data;
    }
    /**
     * aggiunge e sovrascrivere una chiave se presente
     * @param {string} id chiave del oggetto
     * @param {any} value valore dell'oggetto
     */
    forceAdd(id, value){
        this.#data[id] = value;
    }
    /**
     * aggiunge una nuova chiave unica
     * @param {string} id chiave del oggetto
     * @param {any} value valore dell'oggetto
     */
    add(id, value) {
        if(id in this.#data) return false;
        this.#data[id] = value;
        return true;
    }
    /**
     * cambia valore ad un oggetto
     * @param {string} id chiave del oggetto
     * @param {any} newValue valore dell'oggetto
     * @returns il vecchio valore associato alla chiave id
     */
    modify(id, newValue){
        const oldValue = this.#data[id];
        this.#data[id] = newValue;
        return oldValue;
    }
    /**
     * elimina un valore
     * @param {string} id 
     * @returns il valore eliminato
     */
    remove(id) {
        return delete this.#data[id];
    }
}

const GLOBAL_STORE = new Store();

export default class Component {

    #templatePath;
    #container;

    constructor(containerId, templatePath) {
        this.#container = document.getElementById(containerId);
        this.#templatePath = templatePath;
        this.store = GLOBAL_STORE;
    }

    async render() {
        try {
            const response = await fetch(this.#templatePath);
            if (!response.ok) throw new Error(`Template non trovato: ${this.#templatePath}`);
            
            const html = await response.text();
            this.#container.innerHTML = html;

            await this.init();       
        } catch (error) {
            console.error("Errore nel render del componente:", error);
            this.#container.innerHTML = "<p>Errore nel caricamento del componente</p>";
        }
    }

    /**
     * Funzione per effettuare chiamate sulla rete
     * @param {string} url url del backend
     * @param {object} http impostazioni della richiesta HTTP
     * @returns 
     */
    async call(url, http = {}){
        const urlBackend = "./backend/";
        const response = await fetch(urlBackend + url, http);
        if(response.ok) return await response.json();
        else throw new Error("richiesta fallita");
    }

    /**
     * Cambia il componente radice e attiva il Router
     * @param {string} nome nome del componente da caricare
     */
    switchComponent(nome){
        window.location.hash = "#" + nome;
    }

    /**
     * Ricerca e restituisce un oggetto del container DOM associato al componente
     * @param {string} selector 
     * @returns oggetto del DOM oppure NULL
     */
    get(selector){
        return this.#container.querySelector(selector);
    }

    /**
     * 
     * @param {string} selector 
     * @param {any} value valore da scrivere nel nodo DOM
     * @param {boolean} [asHtml=false] - Se true usa innerHTML
     * @returns oggetto del DOM oppure NULL
     */
    set(selector, value, asHtml = false) {
        const el = this.get(selector);
        if (!el) return null;
        
        if (el.tagName === "INPUT" || el.tagName === "TEXTAREA") {
            el.value = value;
        } else {
            asHtml ? el.innerHTML = value : el.textContent = value;
        }
        return el;
    }

    /**
     * Entry point del componente.
     * Ogni componente deve sovrascrivere ed implementare questo metodo
     */
    async init() {}
}