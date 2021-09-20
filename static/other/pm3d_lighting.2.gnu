set terminal pngcairo  transparent enhanced font "arial,10" fontscale 1.0 size 600, 400 
set output 'pm3d_lighting.2.png'
unset border
set style fill   solid 1.00 noborder
set dummy u, v
unset key
set style increment default
set object  1 rect from screen 0, 0 to screen 1, 1
set object  1 behind clip lw 1.0  dashtype solid fc  rgb "gray"  fillstyle   solid 1.00 border lt -1
set parametric
set view 236, 339, 1.245, 1
set isosamples 75, 75
unset xtics
unset ytics
unset ztics
set title "PM3D surfaces with specular highlighting" 
set urange [ -3.14159 : 3.14159 ] noreverse nowriteback
set vrange [ -3.14159 : 3.14159 ] noreverse nowriteback
set xrange [ * : * ] noreverse writeback
set x2range [ * : * ] noreverse writeback
set yrange [ * : * ] noreverse writeback
set y2range [ * : * ] noreverse writeback
set zrange [ * : * ] noreverse writeback
set cbrange [ * : * ] noreverse writeback
set rrange [ * : * ] noreverse writeback
set pm3d depthorder 
set pm3d lighting primary 0.5 specular 0.6
set palette rgbformulae 8, 9, 7
slice(x,y) = (x**2+y**2 < 10.0) ? 1.0 : (x**2+y**2 > 300.0) ? NaN : sin(abs(atan2(x,y)))
sinc2(x,y) = sin(sqrt(x**2+y**2))/sqrt(x**2+y**2)
flatten(x,y) = sqrt(x**2+y**2)/5.
F(x,y) =  sinc2(x,y) * slice(x,y) * flatten(x,y)
## Last datafile plotted: "++"
splot cos(u)+.5*cos(u)*cos(v),sin(u)+.5*sin(u)*cos(v),.5*sin(v) with pm3d,     1+cos(u)+.5*cos(u)*cos(v),.5*sin(v),sin(u)+.5*sin(u)*cos(v) with pm3d
