#!/bin/bash
#
# obtengo_ordenamiento.sh
#
#	Analiza el escalafon y lo carga en la tabla ordenamiento

# Descargo del portal el artículo con los PDF:

BASE=/tmp/base.html

if [ ! -r "$BASE" ]
then
	wget -q -O "$BASE" "http://www.ces.edu.uy/ces/index.php?option=com_content&view=article&id=16495:proyecto-de-escalafon-2016&catid=341&Itemid=510"
fi

ASIGNATURAS='
Astronomía,1
Biología,2,
Contabilidad,3
Dibujo,4
Ed. Física,5
Ed. Musical,6
Ed. Social,7
Filosofía,8
Física,9
Francés,10
Geografía,11
Geología,21
Historia,12
Id. Español,13
Informática,33
Inglés,14
Italiano,15
Literatura,16
Matemática,18
Quimica,19
'

PDFs=`sed 's/[ \t\r\n][ \t\r\n]*/ /g;s/[<>=]/\n/g' "$BASE" | sed 's/^ *"//g;s/" *$//g' | fgrep -i .pdf`

echo "$PDFs" | while read pdf
do
	ASIGNDESC=`echo "$pdf" | sed 's/%20/ /g;s/.*\///;s/\.pdf$//i'`
	ASIGNID=`echo "$ASIGNATURAS" | grep "^$ASIGNDESC," | cut -d, -f2`

	if [ -n "$ASIGNID" ]
	then
		echo "$ASIGNDESC $ASIGNID"
		SQL=""

		OUT="/tmp/$ASIGNID.pdf"
		TXT="/tmp/$ASIGNID.txt"
		if [ ! -r "$TXT" ]
		then
			wget -O "$OUT" "http://www.ces.edu.uy/ces/$pdf"
			pdftotext "$OUT" "$TXT"
		fi
		for fnccedula in `grep '[0-9][0-9][0-9],[0-9][0-9][0-9]-[0-9]' "$TXT" | sed 's/[,-]//g'`
		do
			SQL="$SQL,($ASIGNID,0,$fnccedula)"
		done
		SQL=`echo "$SQL" | sed 's/^,//'`

		SQL="insert into orden values ($ASIGNID,0,0,0);delete from orden where FncEsGrupI=$ASIGNID;insert into orden (FncEsGrupI,FncEsDepto,FncCedula) values $SQL;update orden o join escalafon e using (FncEsGrupI,FncCedula) set o.FncEsDepto=e.FncEsDepto where FncEsGrupI=$ASIGNID and FncEsCargI='000'"
		echo $SQL | mysql -vv legajos

		if [ $? -gt 0 ]
		then
			echo ERROR: en comando SQL
			exit 1
		fi


	fi
done

echo RESUMEN: Docentes en orden que no están en escalafon
mysql legajos --batch --skip-column-names -e "select AsignDesc,count(*) from orden join Estudiantil.ASIGNATURAS on FncEsGrupI=AsignId where FncEsDepto=0 group by FncEsGrupI"

echo RESUMEN: Docentes en el escalafón que no tienen orden
mysql legajos --batch --skip-column-names -e "select AsignDesc,count(*) from escalafon join Estudiantil.ASIGNATURAS on FncEsGrupI=AsignId left join orden using (FncEsGrupI,FncEsDepto,FncCedula) where orden is null group by FncEsGrupI"
