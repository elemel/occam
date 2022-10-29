function normalize(x, y, z)
	local length = math.sqrt(x * x + y * y + z * z)
	return x / length, y / length, z / length, length
end

function randomPointInSphere(random)
	while true do
		local x = love.math.random() * 2 - 1
		local y = love.math.random() * 2 - 1
		local z = love.math.random() * 2 - 1

		if x * x + y * y + z * z <= 1 then
			return x, y, z
		end
	end
end

function randomPointOnSphere()
	return normalize(randomPointInSphere())
end

-- See: https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Line_defined_by_two_points
function distanceFromPointToLine(x, y, ax, ay, bx, by)
	return math.abs((bx - ax) * (ay - y) - (ax - x) * (by - ay))
		/ math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
end

function isBlock(mask, dx, dy)
  assert(-1 <= dx and dx <= 1)
  assert(-1 <= dy and dy <= 1)
  assert(dx ~= 0 or dy ~= 0)
  local n = 3 * (dy + 1) + (dx + 1)

  if n >= 5 then
    n = n - 1
  end

  assert(0 <= n and n <= 7)
  return bit.band(bit.rshift(mask, n), 1) ~= 0
end

function love.load()
	mapSize = 32
	atlasSize = 16
	imageSize = mapSize * atlasSize

	sampleCounts = love.image.newImageData(imageSize, imageSize, "r32f")
	meanLightings = love.image.newImageData(imageSize, imageSize, "r32f")

	imageData = love.image.newImageData(imageSize, imageSize, "rgba32f")
	image = love.graphics.newImage(imageData)
	image:setFilter("linear", "nearest")

  mask = 255
end

function love.update(dt)
	for i = 1, 4096 do
		local mapX = love.math.random(0, atlasSize - 1)
		local mapY = love.math.random(0, atlasSize - 1)

		local mask = 16 * mapY + mapX

		local pixelX = love.math.random(0, mapSize - 1)
		local pixelY = love.math.random(0, mapSize - 1)

		local globalPixelX = mapX * mapSize + pixelX
		local globalPixelY = mapY * mapSize + pixelY

		local ax = (pixelX + 0.5) / mapSize
		local ay = (pixelY + 0.5) / mapSize

		local sampleCount = sampleCounts:getPixel(globalPixelX, globalPixelY)
		local meanLighting = meanLightings:getPixel(globalPixelX, globalPixelY)

		for j = 1, 16 do
			local dx, dy = randomPointOnSphere()
			local radius = love.math.random()

			local bx = ax + radius * dx
			local by = ay + radius * dy

			local blockDx = math.floor(bx)
			local blockDy = math.floor(by)

			local lighting = 1

			if blockDx ~= 0 or blockDy ~= 0 then
				if isBlock(mask, blockDx, blockDy) then
					lighting = 0
				else
					if blockDx ~= 0 and blockDy ~= 0 then
						if
							distanceFromPointToLine(blockDx, 0, ax, ay, bx, by)
							< distanceFromPointToLine(0, blockDy, ax, ay, bx, by)
						then
							lighting = isBlock(mask, blockDx, 0) and 0 or 1
						else
							lighting = isBlock(mask, 0, blockDy) and 0 or 1
						end
					end
				end
			end

			meanLighting = (meanLighting * sampleCount + lighting) / (sampleCount + 1)
			sampleCount = sampleCount + 1
		end

		sampleCounts:setPixel(globalPixelX, globalPixelY, sampleCount, 0, 0, 0)
		meanLightings:setPixel(globalPixelX, globalPixelY, meanLighting, 0, 0, 0)

		local darkenedGray = math.pow(meanLighting, 1)
		imageData:setPixel(globalPixelX, globalPixelY, darkenedGray, darkenedGray, darkenedGray, 1)
	end

	image:replacePixels(imageData)
end

function love.draw()
	local graphicsWidth, graphicsHeight = love.graphics.getDimensions()
	local scale = graphicsHeight / imageSize
	love.graphics.draw(
		image,
		0.5 * graphicsWidth,
		0.5 * graphicsHeight,
		0,
		scale,
		scale,
		0.5 * imageSize,
		0.5 * imageSize
	)

	love.graphics.print(love.timer.getFPS())
end
