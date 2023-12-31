#version 100

precision mediump float;

// Input vertex attributes (from vertex shader)
varying vec2 fragTexCoord;

// Input uniform values
uniform sampler2D texture0;


uniform float screenHeight;

float frequency = 5.0;

void main()
{
    // Scanlines method 2
    float globalPos = (fragTexCoord.y) * (screenHeight / frequency);
    float wavePos = cos((fract(globalPos) - 0.5)*3.14);

    vec4 color = texture2D(texture0, fragTexCoord);

    gl_FragColor = mix(vec4(0.0, 0.0, 0.0, 0.0), color, wavePos);
}