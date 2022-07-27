#!/bin/bash
DIR=$1
TEMP1=0
TEMP2=0
TEMP3=0
TEMP4=0

rm *.txt 2> /dev/null
rm *.dat 2> /dev/null

cat $1/* | sort -n | grep "FORMA_EVASAO" -v > lista_completa.txt
cut -d, -f1 lista_completa.txt | sort -u > criterio_de_busca.txt

while read p;
do
	echo $(grep "$p" lista_completa.txt -c)" "$p >> qtd_evasao_por_tipo.txt
done < criterio_de_busca.txt

cat qtd_evasao_por_tipo.txt | sort -nr > qtd_evasao_por_tipo_ordenado.txt

IFS=$'\n'

echo "[ITEM 3]"
while read p;
do
	echo $p > linha_tipo_ordenado.txt
	echo $(cut -d" " -f2- linha_tipo_ordenado.txt)" "$(cut -d" " -f1 linha_tipo_ordenado.txt)
done < qtd_evasao_por_tipo_ordenado.txt

TEMP1=$1/*

for i in $TEMP1; do
	ANO_EVASAO=$(basename $i .csv | cut -d- -f2)
	for n in $i; do
		TEMP2=$(grep "ANO_INGRESSO" $n -v | cut -d, -f4)
		for k in $TEMP2; do
			echo $[($ANO_EVASAO-$k)] >> qtd_ano_permanecia.txt
		done
	done
done

TEMP3=$(sort -nu qtd_ano_permanecia.txt)
echo "[ITEM 4]"
for i in $TEMP3; do
	echo $(grep "$i" qtd_ano_permanecia.txt -c)" "$i
done

echo "[ITEM 5]"

for i in $TEMP1; do
	ANO=$(basename $i .csv | cut -d- -f2)
	PRIMEIRO_SEM=$(grep "1o" $i -c)
	SEGUNDO_SEM=$(grep "2o" $i -c)
	TOTAL=$[($PRIMEIRO_SEM + $SEGUNDO_SEM)]
	if (( $PRIMEIRO_SEM >$SEGUNDO_SEM)); then
		echo $ANO" "1o. SEMESTRE -" "$[((PRIMEIRO_SEM*100)/TOTAL)]%
	elif (( $SEGUNDO_SEM >$PRIMEIRO_SEM)); then
		echo $ANO" "2o. SEMESTRE -" "$[((SEGUNDO_SEM*100)/TOTAL)]%
	fi
done

MASC=0
FEM=0


for i in $TEMP1; do
	FEM=$(grep "ANO_INGRESSO" $i -v | grep "F$" -c)
	MASC=$(grep "ANO_INGRESSO" $i -v | grep "M$" -c)
	TOTAL=$(grep "ANO_INGRESSO" $i -vc)
	echo $[((MASC*100)/TOTAL)] >> masculino.txt
	echo $[((FEM*100)/TOTAL)] >> feminino.txt
done

echo "[ITEM 6]"
while read p; do
	TEMP4=$[(TEMP4 + $p)]
done < feminino.txt

WC_FEM=$(wc -l < feminino.txt)
echo F" "$[(TEMP4/WC_FEM)]

TEMP4=0
while read p; do
	TEMP4=$[(TEMP4 + $p)]
done < masculino.txt

WC_MASC=$(wc -l < masculino.txt)
echo M" "$[(TEMP4/WC_MASC)]


echo ANO" "EVASOES >> evasoes_ano.dat
for i in $TEMP1; do
	ANO_EVASAO=$(basename $i .csv | cut -d- -f2)
	QTD_EVASAO=$(grep "FORMA_EVASAO" $i -vc)
	echo $ANO_EVASAO" "$QTD_EVASAO >> evasoes_ano.dat
done


gnuplot  <<-EOFMarker 2> /dev/null
set term png
set output "evasoes_ano.png"
set key autotitle columnhead
plot "evasoes_ano.dat" using 1:2 with lines lc 7
EOFMarker




AUX=$(grep "FORMA_EVASAO" lista_completa.txt -v | cut -d, -f3 | sort -u)

LISTA_INGRESSO="ANO"
for i in $AUX; do
	LISTA_INGRESSO+="?"$i
done

echo -e $LISTA_INGRESSO > evasoes_forma.dat

for i in $AUX; do
	echo $i >> criterio_de_ingresso.txt
done




for n in $TEMP1; do

	AUX2=$(basename $n .csv | cut -d- -f2)

 	while read p; do

 		AUX2+="?"$(grep $p $n -c)

	done < criterio_de_ingresso.txt
	echo $AUX2 >> evasoes_forma.dat
	
done

gnuplot -persist <<-EOFMarker 

set term png
set xtics scale 0
set key autotitle columnhead
set style data histogram
set style histogram cluster gap 1
set style fill solid border -1
set datafile separator "?"
set output "evasoes_forma.png"
plot "evasoes_forma.dat" using 2:xtic(1), '' u 3, '' u 4, '' u 5, '' u 6, '' u 7, '' u 8, '' u 9, '' u 10 linecolor rgb 'brown', '' u 11 linecolor rgb 'cyan'
replot

EOFMarker