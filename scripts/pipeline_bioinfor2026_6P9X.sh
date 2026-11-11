#!/usr/bin/env bash
# =============================================================================
# SCRIPT PARA AUTOMATIZAR LA PARTE 2 DEL TP FINAL DE BIOINFORMATICA - COMPLEJO GPCR CRF1 (PDB: 6P9X)
# Pequeña explicacion: Automatizacion integrada para la obtención de secuencias FASTA/GenPept,
#              caracterizacion de patrones estructurales mediante Regex y cuantificación
#              de metricas aminoacidicas utilizando AWK y BioAWK.

# Modo estricto: detiene la ejecucion ante fallos, variables no definidas
# o fallos en tuberías (pipelines).
set -euo pipefail

# -----------------------------------------------------------------------------
# 1 DEFINICIÓN DE VARIABLES GLOBALES Y VERIFICACION DE DEPENDENCIAS
# Este paso no se realizaba previamente pero en la actividad 2
# pero como este es un script y lo puedo llegar a reutilizar en un futuro...
PDB_ID="6P9X"
OUT_FASTA="${PDB_ID}_sequences.fasta"
OUT_GP="${PDB_ID}_sequences.gp"
OUT_COMPLEX="${PDB_ID}_complex_all.fasta"

echo "=== INICIANDO FLUJO DE TRABAJO PARA PDB: ${PDB_ID} ==="

check_dependency() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: La herramienta '$cmd' no está instalada o no se encuentra en el PATH." >&2
        exit 1
    fi
}

echo "[+] Verificando herramientas del entorno Linux (Debian)..."
for tool in esearch efetch awk bioawk perl grep; do
    check_dependency "$tool"
done
echo "    Todas las dependencias están disponibles."

# -----------------------------------------------------------------------------
# 2 OBTENCION DE DATOS (NCBI ENTREZ DIRECT)
echo -e "\n[+] SECCIÓN 1: DESCARGA DE SECUENCIAS DESDE NCBI (ENTREZ DIRECT)"

# 2.1 Consulta directa a la base de datos 'protein' para obtener secuencias FASTA asociadas al PDB
echo "    -> Descargando secuencias en formato FASTA..."
esearch -db protein -query "${PDB_ID}[PDB]" | efetch -format fasta > "${OUT_FASTA}"
echo "       Guardado en: ${OUT_FASTA}"

# 2.2 Consulta directa para extraer el registro anotado en formato GenPept/GenBank
echo "    -> Descargando registros detallados en formato GenPept (GP)..."
esearch -db protein -query "${PDB_ID}[PDB]" | efetch -format gp > "${OUT_GP}"
echo "       Guardado en: ${OUT_GP}"

# 2.3 Enlace cruzado desde la base de datos MMDB/Structure hacia Protein para extraer el complejo completo
echo "    -> Recuperando la totalidad de cadenas del complejo macromolecular via MMDB/elink..."
esearch -db structure -query "${PDB_ID}" | elink -target protein | efetch -format fasta > "${OUT_COMPLEX}"
echo "       Guardado en: ${OUT_COMPLEX}"

# -----------------------------------------------------------------------------
# 3 IDENTIFICACION DE PATRONES FUNCIONALES (REGEX)
echo -e "\n[+] SECCIÓN 2: IDENTIFICACION DE MOTIVOS ESTRUCTURALES MEDIANTE REGEX"

# 3.1 Búsqueda del bucle Walker A / P-loop en la subunidad Gs (GNAS)
# Motif PROSITE: [AG]-x(4)-G-K-[ST] | Regex: [AG].{4}GK[ST]
echo "    -> Búsqueda de patrón Walker A / P-loop (unión a GTP):"
perl -ne 'if(/^>(.*)/){$h=$1}elsif(/[AG].{4}GK[ST]/){print "       Encabezado: $h\n       Coincidencia: $&\n"}' "${OUT_FASTA}"

# 3.2 Búsqueda de sitios de N-glicosilación en el dominio extracelular del receptor CRF1 (CRHR1)
# Motif PROSITE: N-{P}-[ST]-{P} | Regex: N[^P][ST][^P]
echo "    -> Búsqueda de sitios de N-glicosilación en la cadena del receptor CRF1:"
perl -ne 'chomp; if(/^>.*CRHR1/){$f=1} elsif(/^>/){$f=0} elsif($f){$seq.=$_} END{while($seq=~/(N[^P][ST][^P])/g){$pos=pos($seq)-length($1)+1; print "       Sitio N-glicosilación: $1 en posición $pos\n"}}' "${OUT_FASTA}"

# 3.3 Identificación de sitios de procesamiento prohormonal (escisión dibásica) en el precursor de CRF
# Motif Regex: [KR][KR]
echo "    -> Busqueda de sitios de escision dibasica [KR][KR] en el precursor de CRF (CRH_HUMAN):"
grep -A 2 "CRH_HUMAN" "${OUT_FASTA}" | grep -P -o "[KR][KR]" | while read -r match; do
    echo "       Sitio detectado: ${match}"
done

# -----------------------------------------------------------------------------
# 4 CÁLCULO DE MÉTRICAS DE ARVO Y COMPOSICIÓN (AWK Y BIOAWK)
echo -e "\n[+] SECCIÓN 3: CÁLCULO DE MÉTRICAS CON AWK Y BIOAWK"

# 4.1 Conteo total de secuencias presentes en el archivo FASTA principal utilizando AWK
echo -n "    -> "
awk '/^>/{count++} END{print "Cantidad total de secuencias procesadas:", count}' "${OUT_FASTA}"

# 4.2 Determinación de la longitud individual de cada secuencia usando BioAWK (módulo fastx)
echo "    -> Reporte de identificadores y longitud de secuencias (residuos de AA):"
bioawk -c fastx '{print "       ID: " $name "\tLongitud: " length($seq) " aa"}' "${OUT_FASTA}"

# 4.3 Cálculo de la composición global de aminoácidos (frecuencia absoluta y porcentaje relativo)
echo -e "\n    -> Composición aminoacídica global del complejo:"
bioawk -c fastx '{
    len = length($seq);
    total += len;
    for (i = 1; i <= len; i++) {
        aa = substr($seq, i, 1);
        if (aa ~ /[A-Z]/) count[aa]++;
    }
}
END {
    printf "       %-12s %-15s %-15s\n", "Aminoácido", "Frecuencia", "Porcentaje (%)";
    printf "       ---------------------------------------------\n";
    for (a in count) {
        printf "       %-12s %-15d %-15.2f\n", a, count[a], (count[a]/total)*100;
    }
}' "${OUT_FASTA}"

echo -e "\n=== Si ves esto se corrio con totalmente con exito ==="
