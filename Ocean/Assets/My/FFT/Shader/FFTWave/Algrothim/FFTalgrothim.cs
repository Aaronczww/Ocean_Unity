using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFTalgrothim : MonoBehaviour
{
    const int Maxn = 32;

    private int[] r;

    private void Start()
    {
        int n = 8;
        r = new int[n];
        Complex[] f1 = new Complex[Maxn];

        for(int i=0;i<Maxn;i++)
        {
            f1[i] = new Complex(0, 0);
        }

        for (int i = 0; i < n; i++)
        {
            f1[i] = new Complex(i, 0);
            r[i] = i;
        }
        //get_rev(3);

        fft(ref f1, n >> 1, 1);


        //fft_reverse(ref f1, n, 1);

        for (int i=0;i< n; i++)
        {
            Debug.LogWarning(f1[i].real);
        }

        fft(ref f1, n >> 1, -1);

        //fft_reverse(ref f1, n, -1);

        for (int i = 0; i < n; i++)
        {
            Debug.LogWarning((f1[i].real)/n);
        }
    }

    /// <summary>
    /// 递归版本
    /// </summary>
    /// <param name="f"></param>
    /// <param name="len"></param>
    /// <param name="op"></param>
    public void fft(ref Complex[] f,int len,short op)
    {
        if(len == 0)
        {
            return;
        }
        Complex[] fl = new Complex[len + 1];
        Complex[] fr = new Complex[len + 1];

        for(int k=0;k<len;k++)
        {
            fl[k] = f[k << 1];
            fr[k] = f[k << 1 | 1];
        }
        fft(ref fl, len >> 1, op);
        fft(ref fr, len >> 1, op);

        Complex tmp;
        Complex buf;

        tmp = new Complex(Mathf.Cos(Mathf.PI / len), Mathf.Sin(Mathf.PI / len) * op);
        buf = new Complex(1, 0);

        for(int k=0;k<len;k++)
        {
            Complex t = buf.Mul(fr[k]);
            f[k] = fl[k].Add(t);
            f[k + len] = fl[k].Sub(t);   
            buf = buf.Mul(tmp);
        }
    }

    /// <summary>
    /// 二进制反转运算版本
    /// </summary>
    /// <param name="f"></param>
    /// <param name="len"></param>
    /// <param name="op"></param>
    public void fft_reverse(ref Complex[] f,int n,short op)
    {
        for(int i=0;i<n;i++)
        {
            if(i<r[i])
            {
                Complex temp = f[i];
                f[i] = f[r[i]];
                f[r[i]] = temp;
            }
        }
        for(int p=2;p<=n;p<<=1)
        {
            int length = p >> 1;
            Complex tmp = new Complex(Mathf.Cos(Mathf.PI / length), op * Mathf.Sin(Mathf.PI / length));

            for (int k = 0; k < n; k = k + p)
            {
                Complex buf = new Complex(1, 0);
                for(int l=k;l<k+length;l++)
                {
                    Complex tt = buf.Mul(f[length + l]);
                    f[length + l] = f[l].Sub(tt);
                    f[l] = f[l].Add(tt);
                    buf = buf.Mul(tmp);
                }
            }
        }
    }
     
    void get_rev(int bit)//bit表示二进制的位数
    {
        for (int i = 0; i < (1 << bit); i++)//要对1~2^bit-1中的所有数做长度为bit的二进制翻转
            r[i] = (r[i >> 1] >> 1) | ((i & 1) << (bit - 1));//?!! SMG ?!!
    }
}

