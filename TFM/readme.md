# 🛡️ IPS Cognitivo: Defensa Activa con IA (Gemini + pfSense)

## 📝 Resumen del Proyecto
Este proyecto implementa un **Sistema de Prevención de Intrusiones (IPS) Inteligente** que automatiza la detección y mitigación de ataques de fuerza bruta. 

Utilizando el modelo de lenguaje **Gemini AI** como motor de análisis, el sistema procesa los logs de un firewall **pfSense** en tiempo real. Cuando la IA detecta un patrón de ataque (como intentos fallidos de SSH), identifica la dirección IP origen y ejecuta automáticamente una orden de bloqueo en el firewall. Este enfoque transforma una seguridad perimetral estática en una **defensa activa y autónoma** capaz de razonar sobre el contexto de las amenazas.

---

## 🏗️ Arquitectura del Sistema

El flujo de trabajo sigue el siguiente esquema:
1. **pfSense**: Genera logs de eventos de autenticación y los exporta vía Syslog.
2. **Puente (Python)**: Recibe los logs UDP y los convierte en peticiones JSON para la API de n8n.
3. **Cerebro (n8n + Gemini)**: Analiza el texto del log, extrae la IP si hay amenaza o descarta el evento si es tráfico legítimo.
4. **Acción (SSH)**: Ejecuta el bloqueo inmediato en el motor de filtrado de pfSense.

---

## 📂 Descripción de los Archivos

### 🐍 `puente.py`
Script desarrollado en Python que actúa como **Syslog Collector**. 
* Escucha en el puerto `UDP 514`.
* Transforma el log plano en un objeto JSON estructurado.
* Realiza el envío mediante `HTTP POST` hacia el Webhook de n8n.
* Es el componente crítico para permitir la comunicación entre protocolos de red tradicionales y herramientas de automatización modernas.

### ⚙️ `FWPF.json`
Archivo de exportación del **workflow de n8n**. Contiene la lógica de decisión:
* **Webhook**: Recepción de datos.
* **Basic LLM Chain**: Integración con **Google Gemini** mediante Prompt Engineering para distinguir ataques de conexiones exitosas.
* **Nodo If**: Filtro de seguridad que evita ejecuciones innecesarias.
* **Nodo SSH**: Conexión remota al pfSense para ejecutar el comando `easyrule block WAN <IP>`.

---

## 🚀 Instalación y Uso

1. **Configuración de pfSense**:
   - Activar "Remote Logging" hacia la IP donde corre el script de Python.
   - Asegurarse de marcar "General Authentication Events".

2. **Ejecución del Bridge**:
   ```bash
   python3 puente.py
