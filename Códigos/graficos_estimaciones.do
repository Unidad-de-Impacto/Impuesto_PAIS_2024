
* Working directory
if  "`c(username)'" == "tomaspacheco" {
	global main "/Users/tomaspacheco/Documents/GitHub/ImpuestoPais"
}
if  "`c(username)'" == "ariquelme" {
	global main "/Users/ariquelme/Downloads"
}
gl input "$main/input"
gl output "$main/output"
gl code "$main/code"


***** CONSTRUCT DATA SET *****

* Import data set with prices
import excel "precios_productos_jumbo.xlsx", sheet("Sheet1") firstrow clear

* Encode product variable and set panel data set
encode id_producto, gen(prod)
gen time = daily(fecha, "YMD")
format time %td
xtset prod time

* Import characteristics of the products
preserve
tempfile chars
import excel "lista_productos_caracteristicas_sinrep-2.xlsx", sheet("Sheet1") firstrow clear
ren ID id_producto 
split unidad_medida, p(" ")
destring unidad_medida1, replace
replace unidad_medida2 = "gr" if strpos(unidad_medida2, "gr")!=0
replace unidad_medida2 = "ml" if strpos(unidad_medida2, "ml")!=0
replace unidad_medida2 = "u" if strpos(unidad_medida2, "u")!=0
drop link_repetido unidad_medida link
save `chars'
restore

merge m:1 id_producto using `chars'
drop if _m == 1
drop _m id_producto fecha

* Drop products
drop if subcategoria == "borrar" | subcategoria == "Fiambres" | subcategoria == "Aderezos liquidos" | subcategoria == "Sopas"

* 'Imported' status dummy
gen imported = (origen != "Argentina")



* Maximo de dias continuos sin stock
* Crear una variable binaria que indica si no hay stock
gen no_stock = (stock == "OutOfStock")

* Ordenar los datos por producto y tiempo
sort prod time

* Crear una variable que identifique las rachas de días consecutivos sin stock
gen grupo_rachas = no_stock != no_stock[_n-1] if prod == prod[_n-1]
replace grupo_rachas = 0 if grupo_rachas == .

* Asignar números a las rachas
bysort prod (time): gen racha_id = sum(grupo_rachas)

* Calcular el número de días consecutivos sin stock por racha
bysort prod racha_id (time): gen consecutivos_sin_stock = sum(no_stock)

* Mantener solo las rachas sin stock
gen racha_sin_stock = consecutivos_sin_stock if no_stock == 1

* Calcular el máximo de días consecutivos sin stock por producto
bysort prod: egen max_consecutivos_sin_stock = max(racha_sin_stock)
drop no_stock grupo_rachas racha_id consecutivos_sin_stock racha_sin_stock 

* Generate variables for the estimation
gen timeToTreat = time - mdy(9,2,2024)
gen post = (time >= mdy(9,2,2024))
gen post_imported = post*imported
encode subcategoria, gen(categoria_producto)


* Order and sort
order prod origen imported subcategoria categoria_producto unidad_medida1 unidad_medida2 time post timeToTreat post_imported stock max_consecutivos_sin_stock precio  
sort prod time



***** HOMOGENIZE UNITS OF MEASUREMENT *****

* ACEITE: precios por litro
replace unidad_medida1 = 1000/unidad_medida1 if subcategoria == "Aceite"

* ACEITUNAS: precios por 200grs
replace unidad_medida1 = 200/unidad_medida1 if subcategoria == "Aceitunas"

* ADEREZOS LIQUIDOS: precios por 100ml
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Aderezos liquidos"

* ADEREZOS: precios por 500gr 
replace unidad_medida1 = 500/unidad_medida1 if subcategoria == "Aderezos"

* ARROZ: precio por kilo (1000 gr)
replace unidad_medida1 = 1000/unidad_medida1 if subcategoria == "Arroz"

* BEBIDAS VEGETALES: precio por ligro (1000 ml)
replace unidad_medida1 = 1000/unidad_medida1 if subcategoria == "Bebidas vegetales"

* BOMBONES: precio por 250 gr 
replace unidad_medida1 = 250/unidad_medida1 if subcategoria == "Bombones"
 
* CAFE MOLIDO: precio por kilo 
replace unidad_medida1 = 1000/unidad_medida1 if subcategoria == "Cafe molido"

* CAPSULAS DE CAFE: precio por unidad 
replace unidad_medida1 = 1/unidad_medida1 if subcategoria == "Capsulas de cafe"

* CERVEZA: precio por litro 
replace unidad_medida1 = 1000/unidad_medida1 if subcategoria == "Cerveza"

* CHOCOLATE: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Chocolate"

* CONDIMENTO: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Condimento"

* CONDIMENTO LIQUIDO: precio por 250 ml 
replace unidad_medida1 = 250/unidad_medida1 if subcategoria == "Condimento liquido"

* ENLATADOS: precio por 500 gr  
replace unidad_medida1 = 500/unidad_medida1 if subcategoria == "Enlatados"

* FIAMBRES: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Fiambres"

* GALLETITAS: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Galletitas"

* GOLOSINAS: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Golosinas"

* MERMELADA: precio por 500 gr 
replace unidad_medida1 = 500/unidad_medida1 if subcategoria == "Mermelada"

* PASTAS LARGAS: precio por 500 gr 
replace unidad_medida1 = 500/unidad_medida1 if subcategoria == "Pastas largas"

* PASTAS CORTAS: precio por 500 gr 
replace unidad_medida1 = 500/unidad_medida1 if subcategoria == "Pastas cortas"

* PESCADO ENLATADO: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Pescado enlatado"

* QUESO: precio por kilo 
replace unidad_medida1 = 1000/unidad_medida1 if subcategoria == "Queso"

* RISOTTO: precio por 250 gr 
replace unidad_medida1 = 250/unidad_medida1 if subcategoria == "Risotto"

* SALSA DE TOMATE: precio por 500 gr 
replace unidad_medida1 = 500/unidad_medida1 if subcategoria == "Salsa de tomate"

* SALSA PREPARADA: precio por 500 gr 
replace unidad_medida1 = 500/unidad_medida1 if subcategoria == "Salsa preparada"

* SNACK: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Snack"

* SOPAS: precio por 100 gr 
replace unidad_medida1 = 100/unidad_medida1 if subcategoria == "Sopas"

* TE: precio por unidad (saquito)
replace unidad_medida1 = 1/unidad_medida1 if subcategoria == "Te"

* YERBA: precio por kilo 
replace unidad_medida1 = 1000/unidad_medida1 if subcategoria == "Yerba"

***** GENERATING PRICE VARIABLES *****

* As products might not be in stock we compute the 'continuos' price variable
* We assume prices do not change if they are not in stock
by prod (time): carryforward precio, gen(precio_cont)

* Generate price standardized by the unit of measurement
gen precio_std = precio_cont*unidad_medida1

* Generate price variation compared to previous day
bys prod: gen price_var = D.precio/L.precio * 100
bys prod: gen price_var_cont = D.precio_cont/L.precio_cont * 100

* Generate a variable with the first price of the product
bysort prod: gen first_price_cont = precio_cont[1]

* Accumulated inflation 
gen price_variation_c = (precio_cont - first_price_cont) / first_price_cont * 100

* Merge exchange rage

preserve
tempfile dolar
import excel "/Users/ariquelme/Downloads/dolar_oficial.xlsx", sheet("Hoja 1") firstrow clear
ren Fecha time
tsset time 
tsfill
carryforward Compra, gen(compra)
carryforward Venta, gen(venta)

* Generate a variable with the first price of the product
sort time
gen first_dolar = 970

* Accumulated ER change
gen dolar_variation = (venta - first_dolar) / first_dolar * 100
keep time dolar_variation
save `dolar'
restore
merge m:1 time using `dolar'

compress



***** PLOTS *****

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

twoway (line precio_cont time if imported == 0, lcolor("$azul_claro")) (line precio_cont time if imported == 1, lcolor("$amarillo")), legend(order(1 "Nacional" 2 "Importado") ring(1) pos(6) cols(2)) tline(2sep2024, lcolor("$azul_oscuro")) ytitle("Precio promedio en pesos") xtitle("") title("Evolución ") tlabel(02sep2024(10)08oct2024 , labsize(small) ) text(10000 23622  "Baja Impuesto País", place(e) box bcolor(gs15)) 
graph export "$output/graficos/nivel_total.png", as(png) name("Graph") replace

keep if time <= mdy(09,30,2024)

twoway (line price_variation_c time if imported == 0, lcolor("$azul_claro")) (line price_variation_c time if imported == 1, lcolor("$amarillo")) (line dolar_variation time if imported == 1, lcolor("$azul_oscuro")), ///
legend(order(1 "Nacional" 2 "Importado" 3 "Dólar oficial") ring(1) pos(6) cols(2) region(fcolor(none))) tline(2sep2024, lcolor("$azul_oscuro") lpattern(dash)) ///
ytitle("Variación promedio de precios nominales") xtitle("") title("Todas las categorías") ///
text(3 23621 "Baja Impuesto País", place(e) box bcolor(gs15) size(small)) ///
tlabel(02sep2024(10)02oct2024, labsize(small)) text(-0.12 23648 "-0.11%", place(e) box bcolor(gs15) size(small)) text(-0.35 23648 "(-2.3% real)", place(e) box bcolor(gs15) size(small)) text(3.2 23648 "+3.2%", place(e) box bcolor(gs15) size(small)) text(2.1 23648 "+2.1%", place(e) box bcolor(gs15) size(small)) ///
graphregion(fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white)) ///
yscale(range(0 4))



graph export "$output/graficos/var_total.png", as(png) name("Graph")  replace


* Precio normalizado al día del tratamiento
gen precio = precio_cont/4309.4352 if imported == 0
replace precio = precio_cont/9663.2381 if imported == 1
twoway (line precio time if imported == 0, lcolor("$azul_claro")) (line precio time if imported == 1, lcolor("$amarillo")), legend(order(1 "Nacional" 2 "Importado") ring(1) pos(6) cols(2)) tline(2sep2024, lcolor("$azul_oscuro")) ytitle("Precio 2sep24 = 1") xtitle("") title("Evolución ") tlabel(02sep2024(10)08oct2024 , labsize(small) )

* Precios normalizados al comienzo de la serie
gen precio2 = precio_cont/4309.4352 if imported == 0
replace precio2 = precio_cont/9713.2381 if imported == 1
twoway (line precio2 time if imported == 0, lcolor("$azul_claro")) (line precio2 time if imported == 1, lcolor("$amarillo")), legend(order(1 "Nacional" 2 "Importado") ring(1) pos(6) cols(2)) tline(2sep2024, lcolor("$azul_oscuro")) ytitle("Precio 29ago24 = 1") xtitle("") title("Evolución ") tlabel(02sep2024(10)08oct2024 , labsize(small) )

restore

keep if time <= mdy(09,30,2024)

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
putpdf image "$output/graficos/nivel_total.png", linebreak width(6)
putpdf paragraph, halign(center)
putpdf image "$output/graficos/var_total.png", linebreak width(6)
	
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
wildbootstrap reg price_variation_c post_imported post imported, cluster(categoria_producto) rseed(444) reps(1000)
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
	







* Only 26 clusters: Wild Boostrap
wildbootstrap reg price_variation_c post_imported post imported, cluster(categoria_producto) rseed(444) reps(1000)














*eventdd price_variation_c, timevar(timeToTreat) method(fe)  graph_op(ytitle("% aumento de precio"))  wboot

reg price_variation_c imported##ibn.post if post == 0, vce(cluster categoria_producto) hascons










br if inlist(id_producto,"imp_98")






wildbootstrap regress price_variation_c imported##i.post if post == 0, cluster(categoria_producto) rseed(12345)


xtdidregress (price_variation_c) (post_imported), group(prod) time(time) repos



reg gdppc treated##ibn.year if after == 0, vce(cluster country1) hascons





