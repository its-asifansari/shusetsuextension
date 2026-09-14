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


local BASE_URL = "https://www.fanmtl.com"


local ext = Require("ReadWN")(BASE_URL, {

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
                return BASE_URL
            end
        },


        {
            name = "Popular Daily Updates",

            increments = true,

            url = function(data)
                return
                    BASE_URL ..
                    "/list/all/all-lastdotime-" ..
                    (data[PAGE] - 1) ..
                    ".html"
            end
        },


        {
            name = "Most Popular",

            increments = true,

            url = function(data)
                return
                    BASE_URL ..
                    "/list/all/all-onclick-" ..
                    (data[PAGE] - 1) ..
                    ".html"
            end
        },


        {
            name = "New to Web Novels",

            increments = true,

            url = function(data)
                return
                    BASE_URL ..
                    "/list/all/all-newstime-" ..
                    (data[PAGE] - 1) ..
                    ".html"
            end
        }

    },

})


----------------------------------------------------------------
-- URL ENCODING
----------------------------------------------------------------

local function urlEncode(value)

    value = tostring(value)

    return value:gsub(
        "([^%w%-_%.~])",
        function(c)
            return string.format(
                "%%%02X",
                string.byte(c)
            )
        end
    )

end


----------------------------------------------------------------
-- ABSOLUTE URL
----------------------------------------------------------------

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
        return BASE_URL .. url
    end


    return BASE_URL .. "/" .. url

end


----------------------------------------------------------------
-- CLEAN IMAGE URL
----------------------------------------------------------------

local function cleanImageURL(url)

    if not url or url == "" then
        return nil
    end


    local lower = url:lower()


    if lower:find("placeholder", 1, true) then
        return nil
    end


    if lower:find("loading", 1, true) then
        return nil
    end


    return absoluteURL(url)

end


----------------------------------------------------------------
-- GET IMAGE FROM ELEMENT
----------------------------------------------------------------

local function getImage(el)

    if not el then
        return nil
    end


    local image


    image = el:attr("data-original")

    image = cleanImageURL(image)

    if image then
        return image
    end


    image = el:attr("data-src")

    image = cleanImageURL(image)

    if image then
        return image
    end


    image = el:attr("data-lazy-src")

    image = cleanImageURL(image)

    if image then
        return image
    end


    image = el:attr("data-cfsrc")

    image = cleanImageURL(image)

    if image then
        return image
    end


    image = el:attr("data-image")

    image = cleanImageURL(image)

    if image then
        return image
    end


    image = el:attr("src")

    image = cleanImageURL(image)

    if image then
        return image
    end


    return nil

end


----------------------------------------------------------------
-- PARSE ONE SEARCH LINK
----------------------------------------------------------------

local function parseSearchLink(el)

    if not el then
        return nil
    end


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
    -- TITLE
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
    -- COVER
    ------------------------------------------------------------

    local imageURL


    local img =
        el:selectFirst("img")


    if img then
        imageURL = getImage(img)
    end


    ------------------------------------------------------------
    -- If the image is a sibling of the link, inspect the
    -- immediate parent result container.
    ------------------------------------------------------------

    if not imageURL then

        local parent =
            el:selectFirst(
                "xpath=.."
            )

        if parent then

            local parentImg =
                parent:selectFirst("img")

            if parentImg then
                imageURL = getImage(parentImg)
            end

        end

    end


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


    local currentPage =
        data[PAGE] or 1


    ------------------------------------------------------------
    -- FanMTL uses EmpireCMS.
    --
    -- The important fields are:
    --
    -- keyboard
    -- show
    -- tempid
    -- tbname
    --
    -- These correspond to FanMTL's search form.
    ------------------------------------------------------------

    local encoded =
        urlEncode(query)


    ------------------------------------------------------------
    -- POST SEARCH
    ------------------------------------------------------------

    local payload =
        "keyboard=" .. encoded ..
        "&show=title" ..
        "&tempid=1" ..
        "&tbname=news"


    local mediaType =
        MediaType(
            "application/x-www-form-urlencoded"
        )


    local body =
        RequestBody(
            payload,
            mediaType
        )


    local headers =
        HeadersBuilder()
            :add(
                "Accept",
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
            )
            :add(
                "Accept-Language",
                "en-US,en;q=0.5"
            )
            :add(
                "Content-Type",
                "application/x-www-form-urlencoded"
            )
            :add(
                "Origin",
                BASE_URL
            )
            :add(
                "Referer",
                BASE_URL .. "/search.html"
            )
            :build()


    local document


    ------------------------------------------------------------
    -- pcall prevents a failed POST from crashing the extension.
    ------------------------------------------------------------

    local postOK, postResult =
        pcall(
            function()

                return RequestDocument(
                    POST(
                        BASE_URL ..
                        "/e/search/index.php",
                        headers,
                        body
                    )
                )

            end
        )


    if postOK then
        document = postResult
    end


    ------------------------------------------------------------
    -- GET FALLBACK
    ------------------------------------------------------------

    if not document then

        local searchURL =
            BASE_URL ..
            "/e/search/" ..
            "?searchget=1" ..
            "&keyboard=" .. encoded ..
            "&show=title" ..
            "&tempid=1" ..
            "&tbname=news"


        local getOK, getResult =
            pcall(
                function()

                    return GETDocument(
                        searchURL
                    )

                end
            )


        if getOK then
            document = getResult
        end

    end


    if not document then
        return {}
    end


    ------------------------------------------------------------
    -- SEARCH RESULTS
    --
    -- Use the actual novel links because those were already
    -- proven to work with FanMTL search.
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

            local href =
                el:attr("href")


            if not href or href == "" then
                return nil
            end


            if not href:match("/novel/") then
                return nil
            end


            ----------------------------------------------------
            -- Deduplicate before Novel creation.
            ----------------------------------------------------

            if seen[href] then
                return nil
            end


            seen[href] = true


            ----------------------------------------------------
            -- Parse result.
            ----------------------------------------------------

            local novel =
                parseSearchLink(el)


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