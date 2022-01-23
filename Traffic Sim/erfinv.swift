//
//  erfinv.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/23/21.
//

// Taken from https://stackoverflow.com/a/36788896/11710275

import Foundation

func erfinv(y: Double) -> Double {
    let center: Double = 0.7
    let a = [0.886226899, -1.645349621,  0.914624893, -0.140543331]
    let b = [-2.118377725,  1.442710462, -0.329097515,  0.012229801]
    let c = [-1.970840454, -1.624906493,  3.429567803,  1.641345311]
    let d = [ 3.543889200,  1.637067800]
    if abs(y) <= center {
        let z = pow(y,2)
        let num = (((a[3] * z + a[2]) * z + a[1]) * z) + a[0]
        let den = ((((b[3] * z + b[2]) * z + b[1]) * z + b[0]) * z + 1.0)
        var x = y * num / den
        x = x - (erf(x) - y)/(2.0 / sqrt(.pi) * exp(-x * x))
        x = x - (erf(x) - y)/(2.0 / sqrt(.pi) * exp(-x * x))
        return x
    }
    else if abs(y) > center && abs(y) < 1.0 {
        let z = pow(-log((1.0-abs(y))/2),0.5)
        let num = ((c[3]*z + c[2])*z + c[1])*z + c[0]
        let den = (d[1]*z + d[0])*z + 1
        // should use the sign function instead of pow(pow(y,2),0.5)
        var x = y/pow(pow(y,2),0.5)*num/den
        x = x - (erf(x) - y)/(2.0/sqrt(.pi)*exp(-x*x))
        x = x - (erf(x) - y)/(2.0/sqrt(.pi)*exp(-x*x))
        return x
    } else if abs(y) == 1 {
        return y * Double(Int.max)
    } else {
        return .nan
    }
}
