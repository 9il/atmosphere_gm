/++
Likelihood maximization algorithms for normal variance mean mixture with unknown scale parameter `beta`.
------
F(x) = ∫_0^∞ Φ((x-αu_i)√u) dG(u) ≈ Σ_i p_i*Φ((x-βu_i)/sqrt(u))
β - beta (unknown)
Φ - standard normal distribution
G - mixture distribution
p - approximation of G, mixture weights (unknown)
------

Example:
--------
import atmosphere;

double[] myGrid, mySample, myNewSample;
//... initialize myGrid and mySample.

auto optimizer = new NormalVarianceMeanMixtureEMAndCoordinate!double(myGrid, mySample.length+1000);

optimizer.sample = mySample;
optimizer.optimize(
	(double betaPrev, double beta, double likelihoodPrev, double likelihood)
		=> likelihood - likelihoodPrev <= 1e-3);

double beta = optimizer.beta;
double[] mixtureWeights = optimizer.weights.dup;


//remove first 50 elements in sample. 
optimizer.popFrontN(50);

//... initialize myNewSample.
//check length <= 1050
assert(myNewSample.length <= 1050);

// add new sample
optimizer.sample = optimizer.sample~myNewSample;
optimizer.optimize(
	(double betaPrev, double beta, double likelihoodPrev, double likelihood)
		=> likelihood - likelihoodPrev <= 1e-3);

double beta2 = optimizer.beta;
double[] mixtureWeights2 = optimizer.weights.dup;
--------
+/
module atmosphere.parametrized.nvmm;

import atmosphere.mixture;
import atmosphere.internal;
import atmosphere.utilities : sumOfLog2s;
import std.algorithm;
import std.range;
import std.numeric;
import std.traits;
import core.stdc.tgmath;
import std.algorithm;
import std.math : isNormal;

static import std.math;

/++
+/
abstract class NormalVarianceMeanMixture(T) : MixtureOptimizer!T, LikelihoodMaximization!T
	if(isFloatingPoint!T)
{

	override void update()
	{
		_log2Likelihood = mixture.sumOfLog2s;
		updateBeta;
	}

	package T[] _sample;
	package const T[] _grid;

	package T _mean;
	package T _beta;
	package T _log2Likelihood;

	mixin LikelihoodMaximizationTemplate!T;
	

	/++
	Constructor
	Params:
		_grid = Array of parameters u. [u_1, ..., u_k]
		maxLength = maximal length of sample
	+/
	this(in T[] _grid, size_t maxLength)
	in
	{
		assert(_grid.length);
		assert(maxLength);
	}
	body
	{
		super(_grid.length, maxLength);
		this._grid = _grid.dup;
		this._sample = new T[maxLength];
		if (!isFeaturesCorrect)
			throw new FeaturesException;
	}

final:

	/++
	Performs optimization.
	Params:
		tolerance = Defines an early termination condition. 
			Receives the current and previous versions of various parameters. 
			The delegate must return true when parameters are acceptable. 
		findRootTolerance = Tolerance for inner optimization.
	Throws: [FeaturesException](atmosphere/mixture/FeaturesException.html) if [isFeaturesCorrect](atmosphere/mixture/LikelihoodMaximization.isFeaturesCorrect.html) is false.
	See_Also: $(STDREF numeric, findRoot)
	+/
	void optimize(
			scope bool delegate (
				T betaPrev, 
				T beta, 
				T log2LikelihoodValuePrev, 
				T log2LikelihoodValue, 
				in T[] weightsPrev, 
				in T[] weights,
			) 
			tolerance,
			scope bool delegate(T a, T b) @nogc nothrow findRootTolerance = null,
		)
	{
		if (!isFeaturesCorrect)
			throw new FeaturesException;
		T log2LikelihoodPrev, betaPrev;
		scope T[] weightsPrev = new T[weights.length];
		do
		{
			log2LikelihoodPrev = _log2Likelihood;
			betaPrev = _beta;
			assert(weights.length == weightsPrev.length);
			weightsPrev[] = weights[];
			eval(findRootTolerance);
		}
		while(!tolerance(betaPrev, _beta, log2LikelihoodPrev, _log2Likelihood, weightsPrev, weights));
	}


	///ditto
	void optimize(
			scope bool delegate (
				T betaPrev, 
				T beta, 
				T log2LikelihoodValuePrev, 
				T log2LikelihoodValue, 
			) 
			tolerance,
			scope bool delegate(T a, T b) @nogc nothrow findRootTolerance = null,
		)
	{
		if (!isFeaturesCorrect)
			throw new FeaturesException;
		T log2LikelihoodPrev, betaPrev;
		do
		{
			log2LikelihoodPrev = _log2Likelihood;
			betaPrev = _beta;
			eval(findRootTolerance);
		}
		while(!tolerance(betaPrev, _beta, log2LikelihoodPrev, _log2Likelihood));
	}

	///ditto
	void optimize(
			scope bool delegate (
				T betaPrev, 
				T beta, 
				in T[] weightsPrev, 
				in T[] weights,
			) 
			tolerance,
			scope bool delegate(T a, T b) @nogc nothrow findRootTolerance = null,
		)
	{
		if (!isFeaturesCorrect)
			throw new FeaturesException;
		T betaPrev;
		scope T[] weightsPrev = new T[weights.length];
		do
		{
			betaPrev = _beta;
			assert(weights.length == weightsPrev.length);
			weightsPrev[] = weights[];
			eval(findRootTolerance);
		}
		while(!tolerance(betaPrev, _beta, weightsPrev, weights));
	}


	/++
	Sets sample and recalculates beta and mixture.
	Params:
		_sample = new sample with length less or equal `maxLength`
	Throws: [FeaturesException](atmosphere/mixture/FeaturesException.html) if [isFeaturesCorrect](atmosphere/mixture/LikelihoodMaximization.isFeaturesCorrect.html) is false.
	+/
	void sample(in T[] _sample) @property
	in
	{
		assert(_sample.length <= this._sample.length);
		foreach(s; _sample)
		{
			assert(std.math.isFinite(s));
		}
		assert(_featuresT.matrix.shift >= _sample.length);
	}
	body
	{
		reset;
		_featuresT.reserveBackN(_sample.length);
		this._sample[0.._sample.length] = _sample[];
		_mean = sample.sum/sample.length;
		updateBeta;
		assert(_featuresT.matrix.width == _sample.length);
		updateComponents;
		if (!isFeaturesCorrect)
			throw new FeaturesException;
	}

	/++
	Returns: Const slice of the internal sample representation.
	+/
	const(T)[] sample() @property const
	{
		return _sample[0..mixture.length];
	}

	/++
	Returns: sample mean
	+/
	T mean() @property const
	{
		return _mean;
	}


	T log2Likelihood() @property const
	{
		return _log2Likelihood;
	}

	/++
	Returns: beta
	+/
	T beta() @property const
	{
		return _beta;
	}


	/++
	Returns: Const slice of the internal grid representation.
	+/
	const(T)[] grid() @property const
	{
		return _grid;
	}

	package void updateBeta()
	in
	{
		assert(weights.length == _grid.length);
	}
	body
	{
		_beta =  _mean / dotProduct(weights, _grid);
	}


	package void updateComponents()
	{
		auto m = _featuresT.matrix;
		assert(m.width == sample.length);
		version(atmosphere_gm_parallel)
		{
			import std.parallelism;
			//TODO: choice workUnitSize
			debug pragma(msg, "NormalVarianceMeanMixture.updateComponents: parallel");
			auto pdfs = _grid.map!(u => PDF(beta, u)).parallel;
			foreach(i, pdf; _grid.map!(u => PDF(beta, u)).parallel)
			{
				auto r = m[i];
				foreach(x; sample)
				{
					r.front = pdf(x);
					r.popFront;
				}
			}
		}
		else
		{
			foreach(pdf; _grid.map!(u => PDF(beta, u)))
			{
				auto r = m.front;
				m.popFront;
				foreach(x; sample)
				{
					r.front = pdf(x);
					r.popFront;
				}
			}
		}
		updateMixture;
	}

	static struct PDF
	{
		T betau;
		T sqrtu;

		this(T beta, T u) inout
		{
			assert(u > 0);
			this.betau = beta*u;
			this.sqrtu = sqrt(u);
			assert(sqrtu > 0);
		}

		T opCall(T x) inout
		{
			immutable y = (x - betau) / sqrtu;
			enum T c = 0.398942280401432677939946059934381868475858631164934657665925;
			return c * exp(y * y / -2) / sqrtu;
		}
	}
}


/++
Expectation–maximization algorithm
+/
final class NormalVarianceMeanMixtureEM(T) : NormalVarianceMeanMixture!T
	if(isFloatingPoint!T)
{
	private T[] pi;
	private T[] c;

	/++
	Constructor
	Params:
		_grid = Array of parameters u. [u_1, ..., u_k]
		maxLength = maximal length of sample
	+/
	this(in T[] _grid, size_t maxLength)
	in
	{
		assert(maxLength);
	}
	body
	{
		super(_grid, maxLength);
		pi = new T[_sample.length];
		c = new T[_grid.length];
	}

	~this()
	{
		pi.destroy;
		c.destroy;
	}

	override void eval(scope bool delegate(T a, T b) @nogc nothrow findRootTolerance = null)
	{
		EMIteration!
			((a, b) {foreach(i, ai; a) b[i] = 1/ai;}, T)
			(features, _weights, mixture, pi[0..length], c);
		updateComponents;
	}
}


/++
Expectation–maximization algorithm with inner gradient descend optimization.
+/
final class NormalVarianceMeanMixtureEMAndGradient(T) : NormalVarianceMeanMixture!T
	if(isFloatingPoint!T)
{
	private T[] pi;
	private T[] xi;
	private T[] gamma;
	private T[] c;

	/++
	Constructor
	Params:
		_grid = Array of parameters u. [u_1, ..., u_k]
		maxLength = maximal length of sample
	+/
	this(in T[] _grid, size_t maxLength)
	{
		super(_grid, maxLength);
		pi = new T[_sample.length];
		xi = new T[_sample.length];
		gamma = new T[_sample.length];
		c = new T[_grid.length];
	}

	~this()
	{
		pi.destroy;
		xi.destroy;
		gamma.destroy;
		c.destroy;
	}

	override void eval(scope bool delegate(T a, T b) @nogc nothrow findRootTolerance = null)
	{
		gradientDescentIteration!
			((a, b) {foreach(i, ai; a) b[i] = -1/ai;}, T)
			(features, _weights, mixture, pi[0..length], xi[0..length], gamma[0..length], c, findRootTolerance is null ? (a, b) => false : findRootTolerance);
		updateComponents;
	}
}


/++
Expectation–maximization algorithm with inner coordinate descend optimization.
Speed depends on permutation of elements of `grid`.
+/
final class NormalVarianceMeanMixtureEMAndCoordinate(T) : NormalVarianceMeanMixture!T
	if(isFloatingPoint!T)
{
	private T[] pi;

	/++
	Constructor
	Params:
		_grid = Array of parameters u. [u_1, ..., u_k]
		maxLength = maximal length of sample
	+/
	this(in T[] _grid, size_t maxLength)
	{
		super(_grid, maxLength);
		pi = new T[_sample.length];
	}

	~this()
	{
		pi.destroy;
	}

	override void eval(scope bool delegate(T a, T b) @nogc nothrow findRootTolerance = null)
	{
		coordinateDescentIterationPartial!
			(a => -1/a, T)
			(features, _weights, _mixture[0..mixture.length], pi[0..length], findRootTolerance is null ? (a, b) => false : findRootTolerance);
		updateComponents;
	}
}


unittest {
	alias C0 = NormalVarianceMeanMixtureEM!(double);
	alias C1 = NormalVarianceMeanMixtureEMAndCoordinate!(double);
	alias C2 = NormalVarianceMeanMixtureEMAndGradient!(double);
}
