#!/usr/bin/env lua
matrix = require 'matrix'
gnuplot = require 'gnuplot'
require 'ext'

--[[ all_distribution.txt already is in terms of the score
local fn = ... or 'all_distribution.txt'
local d = file[fn]:trim():split'\n':map(tonumber:nargs(1))
--]]

local fn = ...
local d = file[fn]:trim():split'\n':mapi(function(v,k,t)
	v = math.floor(tonumber(v))
	t[v] = (t[v] or 0) + 1
end)
local minx = d:keys():inf()
local maxx = d:keys():sup()
--d = d:mapi(function(v,k) return v, k-minx+1 end)
for i=1,table.maxn(d) do d[i] = d[i] or 0 end

function gaussian(x, sigma) 
	return matrix.lambda({#x}, function(i) 
		if sigma==0 then return x[i] end 
		local sum,ksum=0,0 
		for j=1,#x do 
			local y = (i-j)/sigma 
			local k = math.exp(-y*y) 
			sum=sum+x[j]*k 
			ksum=ksum+k 
		end 
		return sum/math.max(ksum,1e-7) 
	end) 
end

local sigmas = range(0,10,.1)

gnuplot(table(
	{
		xlabel='value', 
		ylabel='count', 
		cblabel='gaussian sigma', 
		persist=true, 
		style='data lines', 
		data=sigmas:mapi(function(sigma) 
			return gaussian(d, sigma) 
		end)
--		:append{
--			range(minx,maxx,(maxx-minx)/100),
--		}
	}, 
	sigmas:mapi(function(sigma,i) 
		return {
			using= 0 -- (#sigmas+1)
				..':'..i..':('..sigma..')',
			title='',
			palette=true,
		} 
	end)
))
