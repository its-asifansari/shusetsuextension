-- {"id":1308639971,"ver":"1.0.6","libVer":"1.0.0","author":"Jobobby04 / fixed","dep":["ReadWN>=1.0.11"]}

local GENRES = {
    "All",
    "Action",
    "Adventure",
    "Comedy",
    "Contemporary Romance",
    "Drama",
    "Eastern Fantasy",
    "Ecchi",
    "Fantasy",
    "Fantasy Romance",
    "Gender Bender",
    "Harem",
    "Historical",
    "Horror",
    "Josei",
    "Lolicon",
    "Magical Realism",
    "Martial Arts",
    "Mecha",
    "Mystery",
    "Psychological",
    "Romance",
    "School Life",
    "Sci-fi",
    "Seinen",
    "Shoujo",
    "Shounen",
    "Shounen Ai",
    "Slice of Life",
    "Smut",
    "Sports",
    "Supernatural",
    "Tragedy",
    "Video Games",
    "Wuxia",
    "Xianxia",
    "Xuanhuan",
    "Yaoi",
    "Fan-Fiction",
    "Urban",
    "Virtual Reality",
    "Faloo",
    "Korean",
}


local ext = Require("ReadWN")("https://www.fanmtl.com", {

    id = 1308639971,

    name = "FansMTL",

    imageURL =
        "https://jobobby04.github.io/ShosetsuExtensions/master/icons/fans_mtl.png",

    shrinkURLNovel = "^.-fanmtl%.com",

    hasCloudFlare = true,

    genres = GENRES,


    listingsMap = {

        {
            name = "Recently Added Chapters",

            increments = false,

            selector =
                "#latest-updates .novel-list.grid.col .novel-item a",

            url = function(data)
                return "https://www.fanmtl.com"
            end
        },


        {
            name = "Popular Daily Updates",

            increments = true,

            url = function(data)

                return
                    "https://www.fanmtl.com/list/all/all-lastdotime-" ..
                    (data[PAGE] - 1) ..
                    ".html"

            end
        },


        {
            name = "Most Popular",

            increments = true,

            url = function(data)

                return
                    "https://www.fanmtl.com/list/all/all-onclick-" ..
                    (data[PAGE] - 1) ..
                    ".html"

            end
        },


        {
            name = "New to Web Novels",

            increments = true,

            url = function(data)

                return
                    "https://www.fanmtl.com/list/all/all-newstime-" ..
                    (data[PAGE] - 1) ..
                    ".html"

            end
        }

    },
})


----------------------------------------------------------------
-- URL HELPERS
----------------------------------------------------------------

local function urlEncode(str)

    str = tostring(str)

    return str:gsub(
        "([^%w%-_%.~])",
        function(c)
            return string.format(
                "%%%02X",
                string.byte(c)
            )
        end
    )

end


local function absoluteURL(url)

    if not url or url == "" then
        return nil
    end


    if url:match("^https?://") then
        return url
    end


    if url:sub(1, 2) == "//" then
        return "https:" .. url
    end


    if url:sub(1, 1) == "/" then
        return "https://www.fanmtl.com" .. url
    end


    return "https://www.fanmtl.com/" .. url

end


----------------------------------------------------------------
-- IMAGE HELPERS
----------------------------------------------------------------

local function cleanImageURL(url)

    if not url or url == "" then
        return nil
    end


    -- Ignore obvious placeholder images.
    local lower = url:lower()

    if lower:find("placeholder", 1, true) then
        return nil
    end


    if lower:find("loading", 1, true) then
        return nil
    end


    if lower:find("default", 1, true) then
        return nil
    end


    return absoluteURL(url)

end


local function getImageFromElement(el)

    if not el then
        return nil
    end


    ------------------------------------------------------------
    -- Lazy-loading attributes
    ------------------------------------------------------------

    local imageURL


    imageURL = el:attr("data-original")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    imageURL = el:attr("data-src")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    imageURL = el:attr("data-lazy-src")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    imageURL = el:attr("data-cfsrc")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    imageURL = el:attr("data-image")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    imageURL = el:attr("data-bg")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    imageURL = el:attr("data-background-image")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    ------------------------------------------------------------
    -- Normal src
    ------------------------------------------------------------

    imageURL = el:attr("src")

    imageURL = cleanImageURL(imageURL)

    if imageURL then
        return imageURL
    end


    ------------------------------------------------------------
    -- CSS background-image
    ------------------------------------------------------------

    local style = el:attr("style")

    if style and style ~= "" then

        local bg =
            style:match(
                "background%-image%s*:%s*url%(['\"]?([^'\")]+)"
            )

        if bg then

            imageURL = cleanImageURL(bg)

            if imageURL then
                return imageURL
            end

        end

    end


    return nil

end


----------------------------------------------------------------
-- NOVEL PARSER
----------------------------------------------------------------

local function makeNovel(el)

    if not el then
        return nil
    end


    ------------------------------------------------------------
    -- Novel URL
    ------------------------------------------------------------

    local href = el:attr("href")


    if not href or href == "" then
        return nil
    end


    if not href:match("/novel/") then
        return nil
    end


    local link = absoluteURL(href)


    if not link then
        return nil
    end


    ------------------------------------------------------------
    -- Title
    ------------------------------------------------------------

    local title


    local titleEl =
        el:selectFirst(
            ".novel-title, .title, h3, h4"
        )


    if titleEl then
        title = titleEl:text()
    end


    if not title or title == "" then
        title = el:text()
    end


    if not title or title == "" then
        return nil
    end


    title = title:gsub("^%s+", "")
    title = title:gsub("%s+$", "")


    if title == "" then
        return nil
    end


    ------------------------------------------------------------
    -- Cover image
    ------------------------------------------------------------

    local imageURL


    ------------------------------------------------------------
    -- First check an image INSIDE the novel link.
    ------------------------------------------------------------

    local img = el:selectFirst("img")


    if img then
        imageURL = getImageFromElement(img)
    end


    ------------------------------------------------------------
    -- Sometimes the link itself carries the image.
    ------------------------------------------------------------

    if not imageURL then
        imageURL = getImageFromElement(el)
    end


    ------------------------------------------------------------
    -- Build Novel
    ------------------------------------------------------------

    return Novel {
        title = title,
        link = link,
        imageURL = imageURL
    }

end


----------------------------------------------------------------
-- SEARCH
----------------------------------------------------------------

ext.search = function(data)

    local query = data[QUERY]


    if not query or query == "" then
        return {}
    end


    ------------------------------------------------------------
    -- FanMTL uses EmpireCMS search.
    --
    -- Do NOT request each novel page here.
    ------------------------------------------------------------

    local searchURL =
        "https://www.fanmtl.com/e/search/" ..
        "?searchget=1" ..
        "&keyboard=" ..
        urlEncode(query) ..
        "&show=title"


    local document = GETDocument(searchURL)


    if not document then
        return {}
    end


    ------------------------------------------------------------
    -- FanMTL search results expose the novel URLs directly.
    ------------------------------------------------------------

    local links =
        document:select(
            "a[href*='/novel/']"
        )


    if not links then
        return {}
    end


    local results = {}

    local seen = {}


    map(
        links,
        function(el)

            local href = el:attr("href")


            if not href or href == "" then
                return nil
            end


            if not href:match("/novel/") then
                return nil
            end


            ----------------------------------------------------
            -- Deduplicate BEFORE creating Novel.
            ----------------------------------------------------

            if seen[href] then
                return nil
            end


            seen[href] = true


            ----------------------------------------------------
            -- Parse result.
            ----------------------------------------------------

            local novel = makeNovel(el)


            if novel then
                table.insert(
                    results,
                    novel
                )
            end


            return nil

        end
    )


    return results

end


----------------------------------------------------------------
-- RETURN EXTENSION
----------------------------------------------------------------

return ext