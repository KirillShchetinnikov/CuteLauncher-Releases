package com.leanbitlab.ltvL;

public final class NightPopupFilterTest {
    public static void main(String[] args) {
        for (int dim : new int[]{0,30,95}) for (int warm : new int[]{0,30,90})
            for (double intensity : new double[]{0,.5,1}) {
                float[] m=NightPopupFilter.matrix(dim,warm,2700,intensity);
                double d=dim/100.0*intensity,w=warm/100.0*intensity;
                for (double pixel : new double[]{0,100,255}) {
                    double expected=(pixel*(1-w)+255*w)*(1-d);
                    if (Math.abs(m[0]*pixel+m[4]-expected)>.001)
                        throw new AssertionError("Popup RGB differs from main filter");
                }
                if (m[18]!=1 || m[19]!=0) throw new AssertionError("Alpha must be unchanged");
            }
        System.out.println("NightPopupFilterTest passed");
    }
}
