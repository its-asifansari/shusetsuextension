-- {"id":1308639971,"ver":"1.0.8","libVer":"1.0.0","author":"Jobobby04 / fixed","dep":["ReadWN>=1.0.11"]}

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
-- URL HELPERS
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
-- FIX FOR READWN ABSOLUTE URL HANDLING
----------------------------------------------------------------

ext.expandURL = function(url)
    return absoluteURL(url)
end

----------------------------------------------------------------
-- IMAGE HELPERS
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
-- SEARCH RESULT PARSER
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

    local imageURL

    local img =
        el:selectFirst("img")

    if img then
        imageURL = getImage(img)
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

    local encoded =
        urlEncode(query)

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
    -- POST SEARCH
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

            if seen[href] then
                return nil
            end

            seen[href] = true

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
-- SAVE THE ORIGINAL READWN NOVEL PARSER
--
-- We use it ONLY for the novel's metadata.
-- We deliberately disable its chapter loading because its
-- chapter insertion is what caused the UNIQUE constraint error.
----------------------------------------------------------------

local originalParseNovel =
    ext.parseNovel

----------------------------------------------------------------
-- FANMTL CHAPTER PARSER
----------------------------------------------------------------

local function getFanMTLSlug(novelURL)
    if not novelURL then
        return nil
    end

    local slug =
        novelURL:match(
            "/novel/([^/?#]+)%.html"
        )

    return slug
end

local function getChapterNumber(url, title)
    local number

    if url then
        number =
            url:match(
                "_(%d+)%.html"
            )
    end

    if not number and title then
        number =
            title:match(
                "[Cc]hapter%s+(%d+)"
            )
    end

    if number then
        return tonumber(number)
    end

    return nil
end

local function parseFanMTLChapterLinks(document)
    if not document then
        return {}
    end

    local links =
        document:select(
            "a[href*='/novel/']"
        )

    if not links then
        return {}
    end

    local chapters = {}
    local seen = {}

    map(
        links,
        function(el)

            local href =
                el:attr("href")

            if not href or href == "" then
                return nil
            end

            ----------------------------------------------------
            -- FanMTL chapter URLs look like:
            --
            -- /novel/book-name_1.html
            -- /novel/book-name_2.html
            --
            -- The main novel URL does NOT have _number.html.
            ----------------------------------------------------

            if not href:match(
                "/novel/[^/]+_%d+%.html"
            ) then
                return nil
            end

            local fullURL =
                absoluteURL(href)

            if not fullURL then
                return nil
            end

            ----------------------------------------------------
            -- THE IMPORTANT FIX:
            -- Deduplicate BEFORE NovelChapter is created.
            ----------------------------------------------------

            if seen[fullURL] then
                return nil
            end

            seen[fullURL] = true

            local title =
                el:text()

            if title then
                title =
                    title:gsub("^%s+", "")
                title =
                    title:gsub("%s+$", "")
            end

            if not title or title == "" then
                title =
                    "Chapter " ..
                    tostring(
                        getChapterNumber(
                            fullURL,
                            nil
                        ) or ""
                    )
            end

            local number =
                getChapterNumber(
                    fullURL,
                    title
                )

            table.insert(
                chapters,
                {
                    number = number,
                    title = title,
                    link = fullURL
                }
            )

            return nil
        end
    )

    return chapters
end

----------------------------------------------------------------
-- NOVEL PARSER OVERRIDE
----------------------------------------------------------------

ext.parseNovel = function(
    novelURL,
    loadChapters
)

    ------------------------------------------------------------
    -- Let ReadWN handle title, cover, description, author,
    -- genres, status, etc.
    --
    -- FALSE is critical:
    -- don't let ReadWN create its duplicate chapters.
    ------------------------------------------------------------

    local novelInfo =
        originalParseNovel(
            novelURL,
            false
        )

    if not loadChapters then
        return novelInfo
    end

    local slug =
        getFanMTLSlug(
            novelURL
        )

    if not slug then
        return novelInfo
    end

    local allChapters = {}
    local seen = {}

    ------------------------------------------------------------
    -- FanMTL chapter endpoint is paginated.
    --
    -- We check several pages and stop as soon as a page gives
    -- us no new chapters.
    ------------------------------------------------------------

    local page = 1
    local maxPages = 20

    while page <= maxPages do

        local chapterURL =
            BASE_URL ..
            "/e/extend/fy.php?page=" ..
            tostring(page) ..
            "&wjm=" ..
            urlEncode(slug)

        local ok, document =
            pcall(
                function()
                    return GETDocument(
                        chapterURL
                    )
                end
            )

        if not ok or not document then
            break
        end

        local pageChapters =
            parseFanMTLChapterLinks(
                document
            )

        if not pageChapters or
           #pageChapters == 0 then
            break
        end

        local newCount = 0

        for _, chapter in
            ipairs(pageChapters)
        do

            if not seen[chapter.link] then

                seen[chapter.link] = true

                table.insert(
                    allChapters,
                    chapter
                )

                newCount =
                    newCount + 1
            end
        end

        if newCount == 0 then
            break
        end

        page = page + 1
    end

    ------------------------------------------------------------
    -- Sort by chapter number.
    ------------------------------------------------------------

    table.sort(
        allChapters,
        function(a, b)

            if a.number and b.number then
                return a.number < b.number
            end

            if a.number then
                return true
            end

            if b.number then
                return false
            end

            return a.title < b.title
        end
    )

    ------------------------------------------------------------
    -- Convert into Shosetsu NovelChapter objects.
    --
    -- Every URL is already unique here.
    ------------------------------------------------------------

    local chapters = {}

    for i, chapter in
        ipairs(allChapters)
    do

        table.insert(
            chapters,
            NovelChapter {
                order = i,
                title = chapter.title,
                link = chapter.link
            }
        )
    end

    novelInfo:setChapters(
        AsList(chapters)
    )

    return novelInfo
end

return ext