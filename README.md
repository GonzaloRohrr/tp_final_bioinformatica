# Análisis Bioinformático Integrado y Estructural del Complejo GPCR CRF1 (PDB: 6P9X)

## Descripción
Este proyecto automatiza la adquisición de secuencias, caracterización de patrones funcionales mediante Expresiones Regulares (Regex) y cálculo de métricas aminoacídicas del receptor del factor liberador de corticotropina tipo 1 (**CRF1 / CRHR1**) en complejo con la proteína heterotrimérica Gs (PDB ID: 6P9X). Incluye además la inspección 3D y renderizado de motivos conservados en UCSF ChimeraX.

## Prerrequisitos
* **Entrez Direct (EDirect)** (`esearch`, `efetch`, `elink`)
* **Herramientas Unix**: `awk`, `bioawk`, `perl`, `grep`
* **Visualización 3D**: `UCSF ChimeraX` (v1.6+)
* **Control de Versiones**: `Git`

## Instrucciones de Ejecución
1. Clonar el repositorio:
   git clone https://github.com/GonzaloRohrr/tp_final_bioinformatica.git
2. Otorgar permisos de ejecución:
   chmod +x scripts/pipeline_bioinfor2026_6P9X.sh
3. (este paso solo por si falla). Convertir los saltos de línea al formato Unix (LF):
      sed -i 's/\r$//' scripts/pipeline_bioinfor2026_6P9X.sh
5. Ejecutar el pipeline automatizado:
   ./scripts/pipeline_bioinfor2026_6P9X.sh

## Referencias Bibliográficas
* Ma, S., et al. (2020). Cryo-EM structure of Urocortin 1-bound Corticotropin-releasing factor 1 receptor in complex with Gs protein. Molecular Cell, 77(3), 588-598.
* Deussing, J. M., & Chen, A. (2018). The Corticotropin-Releasing Factor Family: Physiology of the Stress Response. Physiological Reviews, 98(4), 2225-2280.
