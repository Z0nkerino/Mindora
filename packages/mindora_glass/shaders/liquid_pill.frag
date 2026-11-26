// Mindora Glass — liquid selection pill.
//
// Draws two rounded rectangles (the leading and trailing edge of a moving
// selection) merged with a smooth minimum, so a moving indicator stretches
// and pinches like a droplet. Adds a soft specular highlight along the top
// rim. Output is premultiplied alpha.
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec4 uRectA;     // x, y, w, h of shape A
uniform vec4 uRectB;     // x, y, w, h of shape B
uniform float uRadius;   // corner radius
uniform float uSmooth;   // smooth-min blend distance (px)
uniform vec4 uColor;     // straight-alpha RGBA fill
uniform float uShine;    // 0..1 highlight strength

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

void main() {
  vec2 p = FlutterFragCoord().xy;

  vec2 ha = uRectA.zw * 0.5;
  vec2 hb = uRectB.zw * 0.5;
  float ra = min(uRadius, min(ha.x, ha.y));
  float rb = min(uRadius, min(hb.x, hb.y));
  float da = sdRoundBox(p - (uRectA.xy + ha), ha, ra);
  float db = sdRoundBox(p - (uRectB.xy + hb), hb, rb);
  float d = smin(da, db, max(uSmooth, 0.001));

  // 1.5 px anti-aliased edge.
  float alpha = 1.0 - smoothstep(-0.75, 0.75, d);
  if (alpha <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // Specular: brightest just inside the top edge, fading downwards.
  float top = min(uRectA.y, uRectB.y);
  float height = max(max(uRectA.w, uRectB.w), 1.0);
  float vy = clamp((p.y - top) / height, 0.0, 1.0);
  float rim = 1.0 - smoothstep(0.0, 2.5, abs(d + 1.25));
  float sheen = (1.0 - smoothstep(0.0, 0.55, vy)) * 0.18 + rim * (1.0 - vy) * 0.55;

  vec3 rgb = mix(uColor.rgb, vec3(1.0), clamp(sheen * uShine, 0.0, 1.0));
  float a = alpha * uColor.a;
  fragColor = vec4(rgb * a, a);
}
