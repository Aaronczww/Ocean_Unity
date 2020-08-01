using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Complex
{
    public float real = 0;
    public float imag = 0;
    public Complex(float a,float b)
    {
        real = a;
        imag = b;
    }
    public Complex Add(Complex a)
    {
        Complex result = new Complex(this.real + a.real, this.imag + a.imag);
        return result;
    }

    public Complex Sub(Complex a)
    {
        Complex result = new Complex(this.real - a.real, this.imag - a.imag);
        return result;
    }

    public Complex Mul(Complex a)
    {
        Complex result = new Complex(this.real * a.real - this.imag * a.imag, this.real * a.imag + this.imag * a.real);
        return result;
    }

    public Complex Div(Complex a)
    {
        float t = a.real * a.real + a.imag * a.imag;
        Complex result = new Complex((real * a.real + imag * a.imag) / t, (imag * a.real - real * a.imag) / t);
        return result;
    }
}
