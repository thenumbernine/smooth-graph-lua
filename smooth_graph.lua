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
local xs = table()
local ys = table()
path(fn):read():trim():split'\n'
:mapi(function(origline,rowindex)
	local line = (origline:match'^([^#]*)' or ''):trim()
	if #line == 0 then return end
	local keystr, valuestr = line:split'%s+':unpack()
	local x = tonumber(keystr)
	if not x then
		usingstrs = true
		x = keystr
		--error("couldn't interpret "..line)
	else
		x = math.floor(x)
	end
	local value
	if valuestr then
		value = tonumber(valuestr)
			or error("failed to parse value from row "..rowindex.." line "..origline)
	else
		value = 1
	end
	xs:insert(x)
	ys:insert(value)
end)
local n = #xs
--local minx = d:keys():inf()
--local maxx = d:keys():sup()
--d = d:mapi(function(v,k) return v, k-minx+1 end)
--for i=1,table.maxn(d) do d[i] = d[i] or 0 end
--print(tolua(d))

local threshold = 1e-5
local function gaussian(sigma)
	return matrix.lambda({n}, function(i)
		if sigma==0 then
			local y = ys[i]
			if not y then
				error("row "..i.." value is nil")
			end
			return y
		end
		local invSigmaSq = 1/sigma^2
		local sum,ksum=0,0
		for j=i,1,-1 do
			local dx = usingstrs and (i - j) or (xs[i] - xs[j])
			local k = math.exp(-invSigmaSq * dx * dx)
			if k < threshold then break end
			sum = sum + ys[j] * k
			ksum = ksum + k
		end
		for j=i+1,n do
			local dx = usingstrs and (i - j) or (xs[i] - xs[j])
			local k = math.exp(-invSigmaSq * dx * dx)
			if k < threshold then break end
			sum = sum + ys[j] * k
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
		xtics = cmdline.xtics,
		xdata = cmdline.xdata,
		timefmt = cmdline.timefmt,
		format = cmdline.format,
		data =
			table{
				xs,
			}:append(
				sigmas:mapi(function(sigma)
					return (gaussian(sigma))
				end)
			),
--		:append{
--			range(minx,maxx,(maxx-minx)/100),
--		}
	},
	sigmas:mapi(function(sigma,i)
		return {
			using = (cmdline.dontusekeys and 0 or 1) -- (#sigmas+1)
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
