@echo off
setlocal disabledelayedexpansion

:: Gestione Nome Progetto (Parametro o Input)
set "projName=%~1"
if "%projName%"=="" (
    set /p projName="[1/6] Nome del progetto: "
)

:: Entry point
set "ep=home"
set /p epH="[2/6] Entry point (default: home): "
if not "%epH%"=="" set "ep=%epH%"

:: Default
set "dbH=localhost"
set /p uH="[3/6] Host DB (default: localhost): "
if not "%uH%"=="" set "dbH=%uH%"

set "dbPort=3306"
set /p uPort="[3.5/6] Porta DB (default: 3306): "
if not "%uPort%"=="" set "dbPort=%uPort%"

set "dbU=root"
set /p uD="[4/6] Utente DB (default: root): "
if not "%uD%"=="" set "dbU=%uD%"

set "dbP="
set /p uP="[5/6] Password DB (default: nessuna): "
if not "%uP%"=="" set "dbP=%uP%"

set "dbN=%projName%"
set /p uDN="[6/6] Nome Database (default: %projName%): "
if not "%uDN%"=="" set "dbN=%uDN%"

:: crea la struttura delle cartelle
mkdir %projName%
cd %projName%
mkdir backend backend\config backend\props components root

:: Database.inc.php
(
echo ^<?php 
echo class Database {
echo   private $pdo; 
echo   public function __construct($host, $port, $db, $user, $password^) { 
echo     $dsn = "mysql:host=$host;port=$port;charset=utf8mb4";
echo     try { 
echo       $this-^>pdo = new PDO($dsn, $user, $password, [ 
echo         PDO::ATTR_ERRMODE =^> PDO::ERRMODE_EXCEPTION, 
echo         PDO::ATTR_DEFAULT_FETCH_MODE =^> PDO::FETCH_ASSOC 
echo       ]^); 
echo       $this-^>build($db^); 
echo     } catch (PDOException $e^) { http_response_code(500^); exit; } 
echo   } 
echo   private function build($db^){ 
echo     $this-^>pdo-^>exec("CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"^);
echo     $this-^>pdo-^>exec("USE `$db` "^); 
echo     $check = $this-^>pdo-^>query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$db'"^)-^>fetchColumn(^);
echo     $path = __DIR__ . "/db.sql"; 
echo     if (file_exists($path^) ^&^& !$check^) { 
echo       $sql = trim(file_get_contents($path^)^); 
echo       if (!empty($sql^)^) { 
echo         $this-^>pdo-^>setAttribute(PDO::ATTR_EMULATE_PREPARES, 1^); 
echo         $this-^>pdo-^>exec($sql^); 
echo       } 
echo     } 
echo   } 
echo   public function sql($query, $params = []^) { 
echo     $stmt = $this-^>pdo-^>prepare($query^); 
echo     $stmt-^>execute($params^); 
echo     return $stmt; 
echo   } 
echo   public function execute($query, $params = []^) { 
echo     try { $this-^>sql($query, $params^); return true; } 
echo     catch (PDOException $e^) { return false; } 
echo   } 
echo   public function query($query, $params = []^) { 
echo     return $this-^>sql($query, $params^)-^>fetchAll(^); 
echo   } 
echo } 
echo class DbUtils { 
echo   private static $con = null;
echo   public static function getDB(^){
echo     if(self::$con === null^) self::$con = new Database("%dbH%", "%dbPort%", "%dbN%", "%dbU%", "%dbP%"^);    
echo     return self::$con;
echo   } 
echo   public static function query($q, $p = [], $db = null^) { 
echo     $d = $db ?? self::getDB(^); 
echo     try { return $d-^>query($q, $p^); } 
echo     catch (Exception $e^) { http_response_code(500^); ^echo json_encode(["SQLError" =^> $e-^>getMessage(^)^]^); exit; } 
echo   } 
echo   public static function execute($q, $p = [], $db = null^) {
echo     $d = $db ?? self::getDB(^); 
echo     return $d-^>execute($q, $p^);
echo   } 
echo }
echo ?^>
) > backend\config\database.inc.php

:: Altri file di configurazione
echo CREATE DATABASE IF NOT EXISTS %dbN%; > backend\config\db.sql
echo USE %dbN%; >> backend\config\db.sql
echo # scrivi qui il codice SQL >> backend\config\db.sql

:: Classe padre dei componenti
(
echo class Store {
echo     #data = {}; 
echo     get(id^) { return this.#data[id]; }
echo     has(id^) { return id in this.#data; }
echo     forceAdd(id, value^){ this.#data[id] = value; }
echo     add(id, value^) { if(id in this.#data^) return false; this.#data[id] = value; return true; }
echo     modify(id, newValue^){ const old = this.#data[id]; this.#data[id] = newValue; return old; }
echo     remove(id^) { return delete this.#data[id]; }
echo }
echo const GLOBAL_STORE = new Store(^);
echo export default class Component {
echo     #templatePath; #container;
echo     constructor(containerId, templatePath^) {
echo         this.#container = document.getElementById(containerId^);
echo         this.#templatePath = templatePath; this.store = GLOBAL_STORE;
echo     }
echo     async render(^) {
echo         try {
echo             const response = await fetch(this.#templatePath^);
echo             if (!response.ok^) throw new Error("Template non trovato"^);
echo             this.#container.innerHTML = await response.text(^);
echo             await this.init(^);       
echo         } catch (error^) { console.error(error^); }
echo     }
echo     async call(url, http = {}^){
echo         const response = await fetch("./backend/" + url, http^);
echo         if(response.ok^) return await response.json(^);
echo         else throw new Error("fallita"^);
echo     }
echo     switchComponent(nome^){ window.location.hash = "#" + nome; }
echo     get(selector^){ return this.#container.querySelector(selector^); }
echo     set(selector, value, asHtml = false^) {
echo         const el = this.get(selector^); if (!el^) return null;
echo         if (el.tagName === "INPUT" ^|^| el.tagName === "TEXTAREA"^) el.value = value;
echo         else asHtml ? el.innerHTML = value : el.textContent = value;
echo         return el;
echo     }
echo     async init(^) {}
echo }
) > root\Component.js

:: router
(
echo const urlComponents = "../components/";
echo async function router(^) {
echo     const container = document.getElementById('app-root'^);
echo     const hash = window.location.hash.substring(1^) ^|^| '%ep%';
echo     history.replaceState(null, "", window.location.pathname^);
echo     const parts = hash.split('/'^);
echo     const componentName = parts[parts.length - 1];
echo     const componentPath = urlComponents + hash + "/" + componentName + ".js";
echo     try {
echo         const module = await import(componentPath^);
echo         const page = new module.default('app-root'^);
echo         await page.render(^);
echo     } catch (error^) { console.error(error^); }
echo }
echo window.addEventListener('hashchange', router^);
echo window.addEventListener('load', router^);
) > root\router.js

(
echo ^<!DOCTYPE html^>
echo ^<html lang="en"^>
echo ^<head^>^<meta charset="UTF-8"^>^<title^>%projName%^</title^>^</head^>
echo ^<body^>^<main id="app-root"^>^</main^>^<script type="module" src="./root/router.js"^>^</script^>^</body^>
echo ^</html^>
) > index.html

:: VSC - crea componenente
echo @echo off > vsc.bat
echo set "cN=%%~1" >> vsc.bat
echo if "%%cN%%"=="" ( echo Errore: specifica nome componente ^& exit /b ) >> vsc.bat
echo set PS_OPTS=-ExecutionPolicy Bypass -Command >> vsc.bat

echo set "P1=$n='%%cN%%'; $p='components/'+$n; $nl=[char]10; New-Item -ItemType Directory -Force -Path $p | Out-Null;" >> vsc.bat

echo set "P2=$h='<link rel=\"stylesheet\" href=\"components/'+$n+'/'+$n+'.css\">' + $nl; Set-Content ($p+'/'+$n+'.html') $h; Set-Content ($p+'/'+$n+'.css') '';" >> vsc.bat

echo set "P3=$js='import Component from \"../../root/Component.js\";' + $nl + $nl + 'export default class '+$n.Substring(0,1).ToUpper()+$n.Substring(1)+'Component extends Component {' + $nl + $nl + '  constructor(containerId) { '+$nl+'    super(containerId, \"components/'+$n+'/'+$n+'.html\"); '+$nl+'  }' + $nl + $nl+  '  async init() { '+$nl+'    console.log(\"'+$n+' pronto!\"); '+$nl+'    //codice--------'+$nl+$nl +'  }' + $nl + '} civilization'; $js=$js.Replace(' civilization',''); Set-Content ($p+'/'+$n+'.js') $js;" >> vsc.bat

echo set "P4=Write-Host '>>> Componente' $n 'creato con successo!' -ForegroundColor Green" >> vsc.bat
echo powershell %%PS_OPTS%% "%%P1%% %%P2%% %%P3%% %%P4%%" >> vsc.bat

:: genera entry point
call ./vsc.bat %ep%

:: end
powershell -NoLogo -NoExit -Command "Clear-Host; Write-Host '========================================' -ForegroundColor Cyan; Write-Host ' Setup VASCULAR completato ' -ForegroundColor Magenta; Write-Host ' Progetto >> %projName% << creato! ' -ForegroundColor White; Write-Host '========================================' -ForegroundColor Cyan;"
