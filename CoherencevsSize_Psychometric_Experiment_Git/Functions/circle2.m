%% Circle drawing function
function h = circle2(x,y,r, radius_Colour)
    d = r*2;
    px = x-r;
    py = y-r;
    h = rectangle('Position',[px py d d],'Curvature',[1,1], FaceColor='None', EdgeColor=radius_Colour);
    daspect([1,1,1])
end
