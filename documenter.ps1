# documenter.ps1
# Script to document the Laboratorio 3 solution in the .docx file natively using PowerShell XML manipulation.

$ErrorActionPreference = "Stop"

# Dynamically resolve filename to avoid hardcoded unicode dashes (em-dash) in the source code
$originalDoc = (Get-ChildItem -Filter "*Matrix build enterprise.docx" | Select-Object -ExpandProperty Name -First 1)
$backupDoc = "$originalDoc.bak"
$tempZip = "temp_document.zip"
$tempExtractDir = "temp_extracted_docx"

Write-Output "Resolved original doc file: $originalDoc"
Write-Output "Starting documentation process..."

# Step 1: Idempotency safety - Backup and restore
if (!(Test-Path $backupDoc)) {
    Write-Output "Creating a backup of the original .docx file..."
    Copy-Item $originalDoc -Destination $backupDoc -Force
} else {
    Write-Output "Backup found. Restoring original from backup before modifying..."
}
Copy-Item $backupDoc -Destination $originalDoc -Force

# Step 2: Prepare temporary files
if (Test-Path $tempExtractDir) {
    Remove-Item $tempExtractDir -Recurse -Force
}
if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force
}

# Step 3: Copy docx to zip and extract
Copy-Item $originalDoc -Destination $tempZip -Force
Expand-Archive -Path $tempZip -DestinationPath $tempExtractDir -Force

# Step 4: Load and modify the document XML
$xmlPath = Join-Path $tempExtractDir "word\document.xml"
Write-Output "Loading word/document.xml..."
[xml]$doc = Get-Content -Path $xmlPath -Raw

# Helper to create a paragraph with OpenXML namespaces
function New-WordParagraph {
    param(
        [string]$Text,
        [string]$Style = $null,
        [bool]$Bold = $false,
        [bool]$Italic = $false,
        [string]$Color = $null
    )
    $ns = $doc.DocumentElement.NamespaceURI
    $p = $doc.CreateElement("w", "p", $ns)
    
    # Paragraph properties (style, spacing)
    $pPr = $doc.CreateElement("w", "pPr", $ns)
    
    # Set spacing to make the document look tight and neat
    $spacing = $doc.CreateElement("w", "spacing", $ns)
    $spacing.SetAttribute("before", $ns, "120") | Out-Null # 6pt before
    $spacing.SetAttribute("after", $ns, "120") | Out-Null  # 6pt after
    $spacing.SetAttribute("line", $ns, "240") | Out-Null   # Single line spacing
    $spacing.SetAttribute("lineRule", $ns, "auto") | Out-Null
    $pPr.AppendChild($spacing) | Out-Null

    if ($Style) {
        $pStyle = $doc.CreateElement("w", "pStyle", $ns)
        $pStyle.SetAttribute("val", $ns, $Style) | Out-Null
        $pPr.AppendChild($pStyle) | Out-Null
    }
    $p.AppendChild($pPr) | Out-Null
    
    # Run
    $r = $doc.CreateElement("w", "r", $ns)
    $rPr = $doc.CreateElement("w", "rPr", $ns)
    
    # Font
    $rFonts = $doc.CreateElement("w", "rFonts", $ns)
    $rFonts.SetAttribute("ascii", $ns, "Calibri") | Out-Null
    $rFonts.SetAttribute("hAnsi", $ns, "Calibri") | Out-Null
    $rPr.AppendChild($rFonts) | Out-Null

    # Bold / Italic / Color
    if ($Bold) {
        $b = $doc.CreateElement("w", "b", $ns)
        $rPr.AppendChild($b) | Out-Null
    }
    if ($Italic) {
        $i = $doc.CreateElement("w", "i", $ns)
        $rPr.AppendChild($i) | Out-Null
    }
    if ($Color) {
        $c = $doc.CreateElement("w", "color", $ns)
        $c.SetAttribute("val", $ns, $Color) | Out-Null
        $rPr.AppendChild($c) | Out-Null
    }
    $r.AppendChild($rPr) | Out-Null
    
    # Text content
    $t = $doc.CreateElement("w", "t", $ns)
    $t.InnerText = $Text
    $r.AppendChild($t) | Out-Null
    
    $p.AppendChild($r) | Out-Null
    return $p
}

# Append elements to document body before the section properties <w:sectPr>
$body = $doc.document.body
$sectPr = $body.sectPr

function Append-Element {
    param($element)
    if ($sectPr) {
        $body.InsertBefore($element, $sectPr) | Out-Null
    } else {
        $body.AppendChild($element) | Out-Null
    }
}

# Injecting Document Sections
Append-Element (New-WordParagraph "" -Style "Normal")
Append-Element (New-WordParagraph "----------------------------------------" -Bold $true)
Append-Element (New-WordParagraph "RESOLUCION Y DOCUMENTACION DEL LABORATORIO" -Bold $true -Color "1F4E78")
Append-Element (New-WordParagraph "" -Style "Normal")

# SECTION 1
Append-Element (New-WordParagraph "1. Diseno de la Matriz y Calculo del Numero de Jobs" -Bold $true -Color "2E75B6")
Append-Element (New-WordParagraph "La estrategia 'strategy/matrix' permite definir combinaciones dinamicas de ejecucion para validar multiples entornos. En este pipeline, configuramos los siguientes parametros:" -Italic $true)
Append-Element (New-WordParagraph "- Sistemas Operativos (os): ubuntu-latest, windows-latest (2 opciones)" -Style "Normal")
Append-Element (New-WordParagraph "- Versiones de Node.js (node-version): 18, 20 (2 opciones)" -Style "Normal")
Append-Element (New-WordParagraph "- Modos de Compilacion (mode): debug, release (2 opciones)" -Style "Normal")
Append-Element (New-WordParagraph "Calculo Inicial (Sin Exclusiones):" -Bold $true)
Append-Element (New-WordParagraph "La expansion cartesiana total generaria: 2 (OS) * 2 (Node) * 2 (Modo) = 8 combinaciones (8 jobs de ejecucion)." -Style "Normal")
Append-Element (New-WordParagraph "Estrategia de Exclusion Aplicada (Parte 2):" -Bold $true)
Append-Element (New-WordParagraph "Excluimos especificamente las configuraciones de Windows en modo debug (windows-latest + debug). Esto se debe a que los builds de depuracion (debug) son muy especificos del desarrollo primario y se validan en profundidad en el entorno Linux (Ubuntu). Excluir Windows debug nos ahorra hasta un 25% de minutos de ejecucion en runners virtuales de Windows (que son computacionalmente mas caros)." -Style "Normal")
Append-Element (New-WordParagraph "Esta exclusion elimina las siguientes 2 combinaciones:" -Style "Normal")
Append-Element (New-WordParagraph "  - windows-latest + Node 18 + debug" -Italic $true)
Append-Element (New-WordParagraph "  - windows-latest + Node 20 + debug" -Italic $true)
Append-Element (New-WordParagraph "Total de Jobs Reales en Ejecucion: 8 (iniciales) - 2 (excluidos) = 6 jobs." -Bold $true -Color "C00000")
Append-Element (New-WordParagraph "" -Style "Normal")

# SECTION 2
Append-Element (New-WordParagraph "2. Inclusiones (Includes) y Variables de Entorno de Produccion" -Bold $true -Color "2E75B6")
Append-Element (New-WordParagraph "Para agregar configuraciones especiales sin expandir la matriz cartesiana de forma redundante, se utilizo la seccion 'include'. Se configuraron las siguientes optimizaciones:" -Style "Normal")
Append-Element (New-WordParagraph "- Configuracion Especial de Produccion: Para el entorno de Ubuntu con Node 20 en modo release (nuestro objetivo oficial de produccion), inyectamos variables adicionales:" -Style "Normal")
Append-Element (New-WordParagraph "  - production: true (Booleano para activar optimizaciones)" -Style "Normal")
Append-Element (New-WordParagraph "  - deploy-target: production-cloud (Ruta del despliegue final)" -Style "Normal")
Append-Element (New-WordParagraph "  - extra-flags: --optimize-all --minify (Parametros para minificar y optimizar el build)" -Style "Normal")
Append-Element (New-WordParagraph "- Optimizaciones Generales de Release: Para el resto de combinaciones en modo 'release' (Ubuntu Node 18 y Windows Node 20), definimos un valor de compilacion por defecto:" -Style "Normal")
Append-Element (New-WordParagraph "  - extra-flags: --optimize" -Style "Normal")
Append-Element (New-WordParagraph "" -Style "Normal")

# SECTION 3
Append-Element (New-WordParagraph "3. Concurrencia y Resiliencia (Fail-Fast)" -Bold $true -Color "2E75B6")
Append-Element (New-WordParagraph "- Concurrencia: Agregamos un bloque 'concurrency' con 'cancel-in-progress: true' basado en la rama actual. Si realizas un push y el pipeline anterior en esa misma rama aun esta ejecutandose, GitHub Actions cancela inmediatamente el pipeline anterior. Esto evita la acumulacion de ejecuciones obsoletas y optimiza el uso de recursos." -Style "Normal")
Append-Element (New-WordParagraph "- Resiliencia con Fail-Fast: Se configuro 'fail-fast: false' bajo la estrategia. De forma predeterminada, si un job de la matriz falla, GitHub cancela todos los demas. Al desactivarlo, permitimos que si el build de Node 18 falla por compatibilidad, los de mas jobs (ej. Node 20 en Ubuntu o Windows) continuen hasta completarse. Asi, el equipo de ingenieria obtiene una radiografia completa de todo el ecosistema en cada ejecucion." -Style "Normal")
Append-Element (New-WordParagraph "" -Style "Normal")

# SECTION 4
Append-Element (New-WordParagraph "4. Job Summary Dinamico (Markdown)" -Bold $true -Color "2E75B6")
Append-Element (New-WordParagraph "En lugar de resumenes de texto plano, implementamos un paso en bash que escribe un informe Markdown completo en la variable especial '$GITHUB_STEP_SUMMARY'. El resumen incluye:" -Style "Normal")
Append-Element (New-WordParagraph "- Tabla Informativa: Indica el OS ejecutor, version runtime de Node, modo del build, estado final (Success/Failed) y el tiempo estimado del runner (1m 15s para Ubuntu, 2m 30s para Windows)." -Style "Normal")
Append-Element (New-WordParagraph "- Bloques de Advertencia Enriquecidos (GitHub Alerts): Si se detecta un build de produccion (Ubuntu, Node 20, release), se genera un cuadro dinamico de tipo 'IMPORTANT' con el destino del despliegue en la nube. Si es release normal, muestra una nota informativa ('NOTE'). Si es debug, muestra un consejo tecnico ('TIP')." -Style "Normal")
Append-Element (New-WordParagraph "" -Style "Normal")

# SECTION 5
Append-Element (New-WordParagraph "5. Guia de Capturas de Pantalla Requeridas" -Bold $true -Color "2E75B6")
Append-Element (New-WordParagraph "Para completar tu entrega escolar o empresarial, debes realizar las siguientes capturas en la interfaz de tu GitHub:" -Italic $true)
Append-Element (New-WordParagraph "- Captura 1 - Ejecucion de la Matriz (6 Jobs):" -Bold $true)
Append-Element (New-WordParagraph "  - Ubicacion: Ve a la pestaña 'Actions' de tu repositorio en GitHub y selecciona la ultima ejecucion del pipeline." -Style "Normal")
Append-Element (New-WordParagraph "  - Que capturar: Toma una captura de pantalla del flujo de trabajo donde se visualice claramente que se han creado exactamente 6 jobs paralelos con los nombres expandidos dinamicamente:" -Style "Normal")
Append-Element (New-WordParagraph "    1. Build and Test (ubuntu-latest | Node 18 | debug)" -Style "Normal")
Append-Element (New-WordParagraph "    2. Build and Test (ubuntu-latest | Node 18 | release)" -Style "Normal")
Append-Element (New-WordParagraph "    3. Build and Test (ubuntu-latest | Node 20 | debug)" -Style "Normal")
Append-Element (New-WordParagraph "    4. Build and Test (ubuntu-latest | Node 20 | release)" -Style "Normal")
Append-Element (New-WordParagraph "    5. Build and Test (windows-latest | Node 18 | release)" -Style "Normal")
Append-Element (New-WordParagraph "    6. Build and Test (windows-latest | Node 20 | release)" -Style "Normal")
Append-Element (New-WordParagraph "- Captura 2 - Resumen del Job (Job Summary):" -Bold $true)
Append-Element (New-WordParagraph "  - Ubicacion: Dentro de la misma ejecucion en la pestaña 'Actions', haz clic en el boton 'Summary' en la esquina superior izquierda." -Style "Normal")
Append-Element (New-WordParagraph "  - Que capturar: Desplazate hacia abajo hasta la seccion del Job Summary. Captura la hermosa tabla generada dinamicamente y el cuadro informativo (Alert) de color que cambia dinamicamente segun la version y modo ejecutado." -Style "Normal")
Append-Element (New-WordParagraph "" -Style "Normal")
Append-Element (New-WordParagraph "----------------------------------------" -Bold $true)
Append-Element (New-WordParagraph "Documentacion autogenerada por Antigravity AI Coding Assistant el $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -Italic $true)

# Step 5: Save and zip back
$doc.Save($xmlPath)
Write-Output "Saved modified XML file. Repackaging zip file into .docx..."

# Compress extracted files back to zip
if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force
}
Compress-Archive -Path "$tempExtractDir\*" -DestinationPath $tempZip -Force

# Replace original docx with the newly generated zip file
Copy-Item $tempZip -Destination $originalDoc -Force

# Step 6: Cleanup
Remove-Item $tempZip -Force
Remove-Item $tempExtractDir -Recurse -Force

Write-Output "Documentation generated successfully! The .docx file has been updated."
