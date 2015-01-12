
Atmosphere GM contains an experimental algorithms for new generation of likelihood maximization methods. The goal of this library is to create an reliable and simple in use technology that can be used by software engineers. Package is growing step by step with mathematical publications.

#### Travis-CI Status
+ [![Build Status](https://travis-ci.org/9il/atmosphere_gm.svg)](https://travis-ci.org/9il/atmosphere_gm) - [Atmosphere GM](https://travis-ci.org/9il/atmosphere_gm)
+ [![Build Status](https://travis-ci.org/9il/atmosphere_gm_test.svg)](https://travis-ci.org/9il/atmosphere_gm_test) - [Atmosphere GM Test](https://travis-ci.org/9il/atmosphere_gm_test)


#Features
 1. Separating mixtures of probability distributions
  + Grid methods
  + Likelihood maximization
  + Optimization over sliding window
 2. Generalized probability distributions
  + Density functions
  + Comulative functions
  + Quantiles
  + Random observations generators


#Documentation
Documentation can be found [here](http://9il.github.io/atmosphere_gm/doc/atmosphere.html).
####Changelog
See [release notes](https://github.com/9il/atmosphere_gm/releases).

#Installation
#### BLAS & LAPACK
* If you're on **Ubuntu**, you can install default package `sudo apt-get install libblas-dev liblapack-dev ` or compile and install optimized [OpenBLAS](https://github.com/xianyi/OpenBLAS).
* **OS X** comes with the [Accelerate framework](https://developer.apple.com/library/mac/documentation/Accelerate/Reference/BLAS_Ref/index.html#//apple_ref/doc/uid/TP40009457) built in.
* Instruction for **Windows x86** (needs to be checked)
	1. Download latest `Win32` BLAS from http://sourceforge.net/projects/openblas/files/.
	2. Make link  `YourProject\blas.lib` to `lib\libopenblas.a`.
	3. Make link  `YourProject\lapack.lib` to `lib\libopenblas.a`.
* Instruction for **Windows x86_64** (needs to be checked)
	1. Download latest `Win64-Int32` BLAS from http://sourceforge.net/projects/openblas/files/.
	2. Make link  `YourProject\blas.lib` to `lib\libopenblas.a`.
	3. Make link  `YourProject\lapack.lib` to `lib\libopenblas.a`.
	4. Use `dub --arch=x86_64` to run project.

#### Intro to D
1. Install D [compiler](http://dlang.org/download.html)
2. Install [DUB registry](http://code.dlang.org/download)
3. Read about [DUB](http://code.dlang.org/about)
4. Read about [DUB package format](http://code.dlang.org/package-format)

#### Atmosphere GM
To use [this package](http://code.dlang.org/packages/atmosphere_gm), put the following dependency into your project's
[dub](http://code.dlang.org/about).json into the dependencies section:
```json
{
	...
	"dependencies": {
		"atmosphere_gm": ">=0.0.10"
	}
}
```

Start with [Atmosphere GM Test](https://github.com/9il/atmosphere_gm_test)

# Compilers and optimization
The [DMD](http://dlang.org/download.html) compiler is easy way to start.
To compile your program in release mode use the following build options
```shell
dub build --build=release
```
## LDC
It is suggested the [LLVM D Compiler](https://github.com/ldc-developers/ldc/releases) be used for benchmarks.
To compile your program in release mode with LDC use the following build options
```
dub build --build=release --compiler=ldc2
```
To fine-tune your program for native CPU add the following code into your `dub.json`:
```
{
	...
	"dflags-ldc": ["-mcpu=native"],
}
```
For more options run `ldc2 -help`.

See also [Atmosphere GM Test](https://github.com/9il/atmosphere_gm_test). 


# Bugs
See [bug list](https://github.com/9il/atmosphere_gm/labels/bug).
