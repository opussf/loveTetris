local gameovermsg = [[
*****  *****  *   * *****
*      *   *  ** ** *
*  **  *****  * * * ***
*   *  *   *  *   * *
*****  *   *  *   * *****

*****  *   *  ***** *****
*   *  *   *  *     *   *
*   *   * *   ***   *****
*   *   * *   *     * **
*****    *    ***** *  **
]]

gameoverbanner = { ["width"] = 0 }
local bannerX, bannerY = 0, 0
while (#gameovermsg > 0) do
	c = string.sub( gameovermsg, 1, 1 )
	if c == "*" then
		table.insert( gameoverbanner, {bannerX, bannerY})
	end
	bannerX = bannerX + 1
	gameoverbanner.width = math.max( gameoverbanner.width, bannerX )
	if c == "\n" then
		bannerY = bannerY + 1
		bannerX = 0
	end
	gameovermsg = string.sub( gameovermsg, 2 )
end
gameoverbanner.height = bannerY
gameoverbanner.width = gameoverbanner.width - 1
return gameoverbanner
