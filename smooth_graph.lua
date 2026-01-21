#!/usr/bin/env lua
matrix = require 'matrix'
gnuplot = require 'gnuplot'
require 'ext'

--[[ all_distribution.txt already is in terms of the score
local fn = ... or 'all_distribution.txt'
local d = path(fn):read():trim():split'\n':map(tonumber:nargs(1))
--]]

local fn, sigmaMax, outfn = table.unpack(cmdline)

local usingstrs
local d = path(fn):read():trim():split'\n'
:filter(function(l)
	return l:sub(1,1) ~= '#'
end)
:mapi(function(line,rowindex,desttable)
	local keystr, valuestr = line:split'%s+':unpack()
	local y = tonumber(keystr)
	if not y then
		usingstrs = true
		y = keystr
		--error("couldn't interpret "..line)
	else
		y = math.floor(y)
	end
	local value = valuestr and assert(tonumber(valuestr)) or 1
	desttable[y] = (desttable[y] or 0) + value
end)
local keys = d:keys():sort()
d = keys:mapi(function(k,_,t)
	return d[k], #t+1
end)
local nd = #d
--local minx = d:keys():inf()
--local maxx = d:keys():sup()
--d = d:mapi(function(v,k) return v, k-minx+1 end)
--for i=1,table.maxn(d) do d[i] = d[i] or 0 end
--print(tolua(d))

local threshold = 1e-5
local function gaussian(sigma)
	return matrix.lambda({nd}, function(i)
		if sigma==0 then return d[i] end
		local invSigmaSq = 1/sigma^2
		local sum,ksum=0,0
		for j=i,1,-1 do
			local y = usingstrs and (i - j) or (keys[i] - keys[j])
			local k = math.exp(-invSigmaSq * y * y)
			if k < threshold then break end
			sum = sum + d[j] * k
			ksum = ksum + k
		end
		for j=i+1,nd do
			local y = usingstrs and (i - j) or (keys[i] - keys[j])
			local k = math.exp(-invSigmaSq * y * y)
			if k < threshold then break end
			sum = sum + d[j] * k
			ksum = ksum + k
		end
		return sum/math.max(ksum,1e-7)
	end)
end

sigmaMax = tonumber(sigmaMax) or 10
print('sigmaMax', sigmaMax)
local sigmas = range(0,1,.01):mapi(function(v) return sigmaMax * v end)

local args = table(
	{
		--savedata = 'results.txt',
		--savecmds = 'cmds.txt',
		xlabel = 'value',
		ylabel = 'count',
		cblabel = 'gaussian sigma',
		style = 'data lines',
		xdata = cmdline.xdata,
		timefmt = cmdline.timefmt,
		data =
			table{
				keys,
			}:append(
				sigmas:mapi(function(sigma)
					return gaussian(sigma)
				end)
			),
--		:append{
--			range(minx,maxx,(maxx-minx)/100),
--		}
	},
	sigmas:mapi(function(sigma,i)
		return {
			using = 1 -- (#sigmas+1)
				..':'..(i+1)..':('..sigma..')',
			title = '',
			palette = true,
		}
	end)
)

if outfn then
	local _,ext = io.getfileext(outfn)
	args.terminal = ext..' size 1600,900 background rgb "white"'
	args.output = outfn
else
	args.persist = true
end

gnuplot(args)
