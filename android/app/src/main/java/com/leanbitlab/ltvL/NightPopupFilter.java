package com.leanbitlab.ltvL;

/** RGB transform equivalent to warmth followed by black dimming; alpha is preserved. */
final class NightPopupFilter {
    static float[] matrix(int dimPercent, int warmthPercent, int temperature, double intensity) {
        double dim=dimPercent/100.0*intensity, warm=warmthPercent/100.0*intensity;
        float scale=(float)((1-warm)*(1-dim));
        double t=temperature/100.0;
        double green=Math.round(Math.max(0,Math.min(255,99.4708025861*Math.log(t)-161.1195681661)));
        double blue=t<=19 ? 0 : Math.round(Math.max(0,Math.min(255,138.5177312231*Math.log(t-10)-305.0447927307)));
        float tint=(float)(warm*(1-dim));
        return new float[]{scale,0,0,0,255*tint, 0,scale,0,0,(float)green*tint,
            0,0,scale,0,(float)blue*tint, 0,0,0,1,0};
    }
}
