***** PLOTS *****

* Working directory

gl input "$main/input"
gl output "$main/output"
gl code "$main/code"

use base_productos.dta

unique prod
drop if max_consecutivos_sin_stock > 4 & max_consecutivos_sin_stock !=.
unique prod


** Graficos por categoría de variación promedio

* Colores
gl azul_oscuro "36 44 79"
gl azul_claro "70 101 139"
gl amarillo "230 184 97"

preserve

collapse (mean) price_variation_c precio_cont dolar_variation, by(imported time)

keep if time <= mdy(09,30,2024)

twoway (line price_variation_c time if imported == 0, lcolor("$azul_claro")) (line price_variation_c time if imported == 1, lcolor("$amarillo")) (line dolar_variation time if imported == 1, lcolor("$azul_oscuro")), ///
legend(order(1 "Nacional" 2 "Importado" 3 "Dólar oficial") ring(1) pos(6) cols(2) region(fcolor(none))) tline(2sep2024, lcolor("$azul_oscuro") lpattern(dash)) ///
ytitle("Variación promedio de precios nominales") xtitle("") title("Todas las categorías") ///
text(3 23621 "Baja Impuesto País", place(e) box bcolor(gs15) size(small)) ///
tlabel(02sep2024(10)02oct2024, labsize(small)) text(-0.12 23648 "-0.11%", place(e) box bcolor(gs15) size(small)) text(-0.35 23648 "(-2.3% real)", place(e) box bcolor(gs15) size(small)) text(3.2 23648 "+3.2%", place(e) box bcolor(gs15) size(small)) text(2.1 23648 "+2.1%", place(e) box bcolor(gs15) size(small)) ///
graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white)) ///
yscale(range(0 4))

# En el gráfico anterior se reporta la variación real para los productos importados, se considera la inflación registrada por INDEC para la categoría "Alimentos y Bebidas no Alcohólicas" (2024-09)
# No es posible realizar el gráfico en términos reales debido a que no se dispone de datos de inflación diarios. 

restore


preserve
collapse (mean) price_variation_c precio_cont, by(subcate imported time)
levelsof subcategoria, l(cate)
foreach c of local cate{
	di "`c'"
	
	sum precio_cont if subcate == "`c'"
	local minyax = round(`r(min)'*0.97)
	local manyax = round(`r(max)'*1.025)
	local yax = round(`r(max)'*1.025)
	di `manyax'
	di `minyax'
	di `yax'
	twoway (line precio_cont time if imported == 0 & subcate == "`c'", lcolor("$azul_claro")) (line precio_cont time if imported == 1 & subcate == "`c'", lcolor("$amarillo")), legend(order(1 "Nacional" 2 "Importado") ring(1) pos(6) cols(2)) tline(2sep2024, lcolor("$azul_oscuro")) ytitle("Precio promedio") xtitle("") title("Categoría `c'") ysc(range(`minyax' `manyax')) text(`yax' 23622  "Baja Impuesto País", place(e) box bcolor(gs15)) ylabel(#4) tlabel(02sep2024(10)08oct2024 , labsize(small) )
graph export "$output/graficos/nivel_`c'.png", as(png) name("Graph") replace
	
	qui sum price_variation_c if subcate == "`c'"	
	sum price_variation_c if subcate == "`c'"
	local minyax = round(`r(min)'*0.97)
	local manyax = round(`r(max)'*1.025)
	local yax = round(`r(max)'*1.025)
	di `manyax'
	di `minyax'
	di `yax'
	twoway (line price_variation_c time if imported == 0 & subcate == "`c'", lcolor("$azul_claro")) (line price_variation_c time if imported == 1 & subcate == "`c'", lcolor("$amarillo")), legend(order(1 "Nacional" 2 "Importado") ring(1) pos(6) cols(2)) tline(2sep2024, lcolor("$azul_oscuro")) ytitle("Variación promedio de precios") xtitle("") title("Categoría `c'") ysc(range(`minyax' `manyax')) text(`yax' 23622  "Baja Impuesto País", place(e) box bcolor(gs15)) ylabel(#4) tlabel(02sep2024(10)08oct2024 , labsize(small) )
	graph export "$output/graficos/var_`c'.png", as(png) name("Graph") replace
}


putpdf begin
putpdf paragraph, halign(center)
	
levelsof subcategoria, l(cate)
foreach c of local cate{
	putpdf paragraph, halign(center)
	putpdf image "$output/graficos/nivel_`c'.png", linebreak width(6)
	
	putpdf paragraph, halign(center)
	putpdf image "$output/graficos/var_`c'.png", linebreak width(6)
	
	putpdf pagebreak
}
putpdf save "$output/graficos.pdf", replace

restore


***** TABLE WITH RESULTS *****

* Table
mat def tabla = J(26, 8, .)
local row = 1
levelsof subcategoria, l(cate)
foreach c of local cate{
	
	* Nacionales Pre
	qui sum precio_cont if imported == 0 & post == 0 & subcate == "`c'"
	mat tabla[`row', 1] = round(`r(mean)', .1)
	
	* Nacionales Post
	qui sum precio_cont if imported == 0 & post == 1 & subcate == "`c'"
	mat tabla[`row', 2] = round(`r(mean)', .1)
	
	* Variacion nacionales
	mat tabla[`row', 3] = (tabla[`row', 2]/tabla[`row', 1] - 1)*100

	* Importados Pre
	qui sum precio_cont if imported == 1 & post == 0 & subcate == "`c'"
	mat tabla[`row', 4] = round(`r(mean)', .1)

	* Importados Post
	qui sum precio_cont if imported == 1 & post == 1 & subcate == "`c'"
	mat tabla[`row', 5] = round(`r(mean)', .1)

	* Variacion importados
	mat tabla[`row', 6] = (tabla[`row', 5]/tabla[`row', 4] - 1)*100

	* Variacion de variacion... 
	mat tabla[`row', 7] = (tabla[`row', 5] -  tabla[`row', 2]) - (tabla[`row', 4] -  tabla[`row', 1])

	local row = `row' + 1
}

frmttable using "resultados.rtf", statmat(tabla) sdec(1) sfmt(f) ctitle("", "NACIONALES", "NACIONALES","NACIONALES",  "IMPORTADOS", "IMPORTADOS ", "IMPORTADOS", "Efecto" \ "", "Antes", "Después", "Var. %" "Antes", "Después", "Var. %", "neto ($)")  rtitle("Aceite" \ "Aceitunas" \ "Aderezos" \ "Arroz" \ "Bebidas vegetales" \ "Bombones" \ "Café molido" \ "Capsulas de café" \ "Cerveza" \ "Chocolate" \ "Condimento" \ "Condimento líquido" \ "Enlatados" \ "Galletitas" \ "Golosinas" \ "Mermelada" \ "Pastas cortas" \ "Pastas largas" \ "Pescado enlatado" \ "Queso" \ "Risotto" \ "Salsa de tomate" \ "Salsa preparada" \ "Snack" \ "Té" \ "Yerba") note("Fuente: elaboración propia con datos de la página web de Jumbo.") replace


stop_pre_regresiones 

***** ECONOMETRIC ESTIMATIONS *****

* MAIN REGRESSIONS

eststo clear

* PRICE VARIATION
* Clustered standard errors
eststo: reg price_variation_c post_imported post imported, cluster(categoria_producto)

* Only 26 clusters: Wild Boostrap
reg price_variation_c post_imported post imported, robust 
boottest {post_imported} ,  boottype(wild) cluster(categoria_producto) seed(444) reps(1000) nogr 

eststo: test post_imported == 0
estadd scalar p_manual = r(p)

* PRICE LEVEL
eststo: reg precio_cont post_imported post imported, cluster(categoria_producto)

* Only 26 clusters: Wild Boostrap
wildbootstrap reg precio_cont post_imported post imported, cluster(categoria_producto) rseed(444) reps(1000)
eststo: test post_imported == 0
estadd scalar p_manual = r(p)


esttab using "$output/tabla", se replace label noobs ///
keep(post_imported) ///
cells(b(fmt(2) star) se(par fmt(2))) ///
stats(p_manual blank N, fmt(2 2 0 2) labels("P-value" "Number of Observations" "R-Squared") layout([@] [@] @ @ @)) 


* Regresiones por categoria

cap erase "$output/categorias.xls"
cap erase "$output/categorias.txt"
levelsof subcategoria, l(cate)
foreach c of local cate{
	qui reg price_variation_c post_imported post imported if subcate == "`c'" 
	outreg2 using "$output/categorias.xls", append keep(post_imported) ctitle("`c'") eqdrop(cons)
}
	


