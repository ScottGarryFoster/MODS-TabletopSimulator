m_objMainDeck = nil -- The Main Deck

m_btnNumberOfButtons = 0
m_iBtnDeal = -1 --Deal Button
m_iBtnShowHideButton = -1 --Deal Button
m_iBtnSmoothMovementButton = -1 --SmoothMovement

m_tbGUIDinDescription = {} -- Tags in Description

--Game Vars
m_iHazzardsCards_count = 0
m_tbHazzardsRemoved = {}
m_iRoundNumber = 0
m_iNumberOfHazzardsOutOfDeck = 0

--Round Vars
m_bRoundIsOn = false
m_bShuffleBeforeDeal = false
m_iCurrentPath = 1
m_iNumberOfPlayersIn = 0
m_iNumberOfHazzards_Spider = 0
m_iNumberOfHazzards_Mummy = 0
m_iNumberOfHazzards_Boulder = 0
m_iNumberOfHazzards_Snake = 0
m_iNumberOfHazzards_Fire = 0
m_bRoundOverDueToHazzards = false
m_sRoundOverDueToHazzard = ""
m_iDealtCards_count = 0
m_tbDealtCards = {}
m_iDontFlipNumber_0 = -1
m_bReadyForNextCard = false

--Deck Recovery
m_bNeedRecovery = false

--Options
m_bDeckHidden = false --State of Deck
m_bSmoothMovement = false--Movecards smoothly

function onLoad()
    createMainButton()
    createShowHideButton()
    createSmoothMovementButton()
    --setDeckHidden(false)
    
    setSmoothMovement(false)
    
    m_tbGUIDinDescription = getTags(self.getDescription(),"")
    m_iCurrentPath = 2
    
    resetRound()
    setDeckButtonLabel("Setup next game")
    --setupDebugTimer()
end

function onCollisionEnter(info)
    local derp = info.collision_object
    if m_bNeedRecovery then
        deckRecovery(derp)
    end
end

function mainButton()
    if m_iRoundNumber == 0 then
        m_iRoundNumber = m_iRoundNumber + 1
        mergeHazardCardsToMainDeck()
        hazardCardsEmpty()
        retractAllCardsToDeck()
        dealtCardsEmpty()
        resetRound()
        setDeckButtonLabel("Start new round")
        
    elseif m_bRoundIsOn then
        if m_bReadyForNextCard == true then
            if m_bShuffleBeforeDeal then
                mainDeckShuffle()
                m_bShuffleBeforeDeal = false
            end
            if dealCardInRound() >= 5 then
                m_bRoundIsOn = false
                m_iRoundNumber = m_iRoundNumber + 1
                if m_iRoundNumber >= 6 then
                    setDeckButtonLabel("Setup next game")
                    m_iRoundNumber = 0
                else
                    setDeckButtonLabel("Start new round")
                end
            else
                setDeckButtonLabel("Deal")
            end
        else
            printToAll("Wooah there buddy. Slow that click down a little.")
        end
    else
        if retractAllCardsToDeck() then
            if m_bRoundOverDueToHazzards then
                moveDoubleHazzardsToBottom(m_sRoundOverDueToHazzard)
            end
            dealtCardsEmpty()
            m_bShuffleBeforeDeal = true
            resetRound()
            setDeckButtonLabel("Deal")
        end
    end
end

function CALLBACKcardhitpath(card)
    m_bReadyForNextCard = true
end
--de1e9e
--3a7ba4 643121 7fd96c 35cf3f 414af8 d2ffb3 42ff95 452a15 4c5d92 ab0899 3e74c7 301212 44549d 135447 5894ba 6ff4eb c884fc 59b770
--832b6f 4ffd93 9bf66e a9440a 8ecbee
--getSnapPoints() --Returns Table

function dealCardInRound()
    --Return values
    -- -1: Could not run for some reason... couldn't find deck etc
    -- 0: Dealt a card round still exists
    -- 5: Two hazzards on table round is automatically over
    if m_iCurrentPath > 19 then --Ran out of paths
        return -1
    elseif m_bRoundOverDueToHazzards == true then
        return 1
    end
    local deck = getDeckObject()
    if deck == false then
        return -1
    end
    local nextPath = getObjectFromGUID(m_tbGUIDinDescription[m_iCurrentPath])
    if nextPath == nil then
        printToAll("Could not find next path. Ensure all paths are in Plaque description.")
        return -1
    end
    
    local card = deck.takeObject() 
    dealtCardsStore(card) --Stores the card in the array
    local vec = nextPath.getPosition()
    vec[2] = vec[2] + 0.5
    flipCardFaceUp(card, true)
    if m_bSmoothMovement then
        card.setPositionSmooth(vec,  false,  true)
    else
        card.setPosition(vec)
    end
    m_bReadyForNextCard = false
    
    local cardType = roundCardTypeCheck(card.getDescription())
    if cardType ~= false and cardType ~= "" then
        if cardType == "hazard" then
            --true in the below adds the hazzard to round totals
            m_sRoundOverDueToHazzard = roundHazzardSpecificCheck(card.getDescription(), true)
            local hazzardEnder = roundHazzardUpdate()
            if hazzardEnder ~= "" then
                markDoubleHazzards(m_sRoundOverDueToHazzard)
                printToAll("Two " .. hazzardEnder .. " cards")
                m_bRoundOverDueToHazzards = true
                return 5
            end
        end
    end
    m_iCurrentPath = m_iCurrentPath + 1
    if m_iCurrentPath > 19 then
        printToAll("Got to the end of the temple")
        return 5
    end
    
    return 0
end

function resetRound()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    flipCardFaceDown(deck)
    deck.randomize()
    
    m_bRoundIsOn = true
    m_iNumberOfPlayersIn = 1
    m_iNumberOfHazzards_Spider = 0
    m_iNumberOfHazzards_Mummy = 0
    m_iNumberOfHazzards_Boulder = 0
    m_iNumberOfHazzards_Snake = 0
    m_iNumberOfHazzards_Fire = 0
    m_bRoundOverDueToHazzards = false
    m_iCurrentPath = 2
    m_sRoundOverDueToHazzard = ""
    m_iDontFlipNumber_0 = -1
    resetAllPathColors()
    m_bReadyForNextCard = true
    return true
end

function resetAllPathColors(newColor)
    if newColor == nil or newColor == "" then
        newColor = "White"
    end
    for i, v in ipairs(m_tbGUIDinDescription) do
        if i == 1 then --is there continue in lua?
        elseif i <= 19 then
            local path = getObjectFromGUID(m_tbGUIDinDescription[i])
            if path == nil then
                printToAll("Could not find path: " .. i)
                return false
            end
            path.setColorTint( stringColorToRGB(newColor) )
            if i == 19 then
                return true
            end
        else
            return true
        end
    end
    return false
end

function mainDeckShuffle()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    deck.randomize()
end

function roundCardTypeCheck(cardDescription)
    if cardDescription == "" then
        return false
    end
    local cardTags = getTags(cardDescription,"#")
    for i, v in ipairs(cardTags) do
        if v == "#hazard" then
            return "hazard"
        elseif v == "#gem" then
            return "gem"
        elseif v == "#artifact" then
            return "artifact"
        end
    end
    return ""
end

function roundHazzardSpecificCheck(cardDescription, addToTotals, storeResult)
    if cardDescription == "" then
        return false
    end
    local cardTags = getTags(cardDescription,"#")
    for i, v in ipairs(cardTags) do
        if v == "#snake" then
            if addToTotals then
                m_iNumberOfHazzards_Snake = m_iNumberOfHazzards_Snake + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "snake"
        elseif v == "#mummy" then
            if addToTotals then
                m_iNumberOfHazzards_Mummy = m_iNumberOfHazzards_Mummy + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "mummy"
        elseif v == "#boulder" then
            if addToTotals then
                m_iNumberOfHazzards_Boulder = m_iNumberOfHazzards_Boulder + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "boulder"
        elseif v == "#fire" then
            if addToTotals then
                m_iNumberOfHazzards_Fire = m_iNumberOfHazzards_Fire + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "fire"
        elseif v == "#spider" then
            if addToTotals then
                m_iNumberOfHazzards_Spider = m_iNumberOfHazzards_Spider + 1
            end
            if storeResult then
                hazardCardsStore(v)
            end
            return "spider"
        end
    end
    return false
end

function roundHazzardUpdate()
    if m_iNumberOfHazzards_Spider >= 2 then
        return "spider"
    elseif m_iNumberOfHazzards_Mummy >= 2 then
        return "mummy"
    elseif m_iNumberOfHazzards_Boulder >= 2 then
        return "boulder"
    elseif m_iNumberOfHazzards_Snake >= 2 then
        return "snake"
    elseif m_iNumberOfHazzards_Fire >= 2 then
        return "fire"
    end
    return ""
end

function markDoubleHazzards(hazzardType)
    local nextFreeHazzard = getNextFreeHazzardPlacementObject()
    if nextFreeHazzard == false then
        return false
    elseif hazzardType == "" then
        return false
    end
    local hazzardTag = false
    
    for i, v in ipairs(m_tbDealtCards) do
        hazzardTag = roundHazzardSpecificCheck(v.getDescription(),false)
        if hazzardTag == hazzardType then
            if m_iDontFlipNumber_0 == -1 then
                m_iDontFlipNumber_0 = i
                hazardCardsStore(v)
                return true
            end
        end
    end
end

function toggleDeckVisibility()
    if m_bDeckHidden == true then
        setDeckHidden(false)
    else
        setDeckHidden(true)
    end
end

function flipCardFaceUp(_card, _isMainDeckCard)
    --Seems the wrong way around.
    --It's this way for the main deck.
    if _isMainDeckCard then
        return flipCardFaceDown(_card)
    end
    if _card.is_face_down then  --Mean card is face down
        _card.flip()
    end
    return true
end

function flipCardFaceDown(_card, _isMainDeckCard)
    if _isMainDeckCard then
        return flipCardFaceUp(_card)
    end
    if _card.is_face_down == false then --Mean card is face up
        _card.flip()
    end
    return true
end

function dealtCardsStore(_card)
    if _card == nil then
        return false
    end
    m_iDealtCards_count = m_iDealtCards_count + 1
    m_tbDealtCards[m_iDealtCards_count] = _card
    return true
end

function dealtCardsEmpty()
    m_iDealtCards_count = 0
    m_tbDealtCards = {}
    return true
end

function hazardCardsStore(_card)
    if _card == nil then
        return false
    end
    m_iHazzardsCards_count = m_iHazzardsCards_count + 1
    m_tbHazzardsRemoved[m_iHazzardsCards_count] = _card
    return true
end

function hazardCardsEmpty()
    m_iHazzardsCards_count = 0
    m_tbHazzardsRemoved = {}
    return true
end

--

function retractAllCardsToDeck()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    local vec = deck.getPosition()
    vec[2] = vec[2] + 1
    for i, v in ipairs(m_tbDealtCards) do
        if v ~= nil and m_iDontFlipNumber_0 ~= i then
            v.setLock(false)
            flipCardFaceDown(v)
            if m_bSmoothMovement then
                v.setPositionSmooth(vec,  false,  true)
            else
                v.setPosition(vec)
            end
        end
    end
    return true
end

function mergeHazardCardsToMainDeck()
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    local vec = deck.getPosition()
    vec[2] = vec[2] + 1
    for i, v in ipairs(m_tbHazzardsRemoved) do
        if v ~= nil then
            v.setLock(false)
            flipCardFaceDown(v)
            if m_bSmoothMovement then
                v.setPositionSmooth(vec,  false,  true)
            else
                v.setPosition(vec)
            end
        end
    end
    m_iNumberOfHazzardsOutOfDeck = 0
    return true
end

function moveDoubleHazzardsToBottom(hazzardType)
    local nextFreeHazzard = getNextFreeHazzardPlacementObject()
    if nextFreeHazzard == false then
        return false
    elseif hazzardType == "" then
        return false
    end
    local hazzardTag = false
    local vec = nextFreeHazzard.getPosition()
    vec[2] = vec[2] + 1
    for i, v in ipairs(m_tbDealtCards) do
        hazzardTag = roundHazzardSpecificCheck(v.getDescription(),false)
        if hazzardTag == hazzardType then
            v.setLock(false)
            flipCardFaceUp(v)
            if m_bSmoothMovement then
                v.setPositionSmooth(vec,  false,  true)
            else
                v.setPosition(vec)
            end
            
            hazzardType = "#nothing" --Only one hazzard is moved
        end
    end
    m_iNumberOfHazzardsOutOfDeck = m_iNumberOfHazzardsOutOfDeck + 1
end

function toggleSmoothMovement()
    if m_bSmoothMovement then
        setSmoothMovement(false)
    else
        setSmoothMovement(true)
    end
end

function setDeckHidden(newValue)
    local deck = getDeckObject()
    if deck == false then
        return false
    end
    
    if newValue then --Hide Deck
        m_bDeckHidden = true
        deck.setInvisibleTo(getSeatedPlayers())
        setShowHideButtonLabel("Hide Deck")
    else --Show Deck
        m_bDeckHidden = false
        deck.setInvisibleTo()
        setShowHideButtonLabel("Show Deck")
    end
end

function setSmoothMovement(newValue)
    if newValue then --Hide Deck
        m_bSmoothMovement = true
        setSmoothMovementButtonLabel("Smooth Movement")
    else --Show Deck
        m_bSmoothMovement = false
        setSmoothMovementButtonLabel("Instant Movement")
    end
end

function setSmoothMovementButtonLabel(newValue)
    if m_iBtnShowHideButton ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnSmoothMovementButton
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function setDeckButtonLabel(newValue)
    if m_iBtnDeal ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnDeal
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function setShowHideButtonLabel(newValue)
    if m_iBtnShowHideButton ~= -1 then
        local button_parameters = {}
        button_parameters.index = m_iBtnShowHideButton
        button_parameters.label = newValue
        self.editButton(button_parameters)
    end
end

function getDeckObject()
    if m_objMainDeck ~= nil then
        m_bNeedRecovery = false
        return m_objMainDeck
    else
        local deck = getObjectFromGUID(m_tbGUIDinDescription[1])
        if deck == nil then
            if findDeckUsingCollider() then
                return m_objMainDeck
            end
            printToAll("Could not find deck. If this keeps happenning drop the deck on the Plaque so I can find it.")
            m_bNeedRecovery = true
            return false
        end
        if findDeckUsingCollider() then
            return m_objMainDeck
        end
        m_objMainDeck = deck
        m_bNeedRecovery = false
        return m_objMainDeck
    end
end

function deckRecovery(obj)
    if obj == nil then
        return false
    end
    if obj.getQuantity() == -1 then --Not a deck
        return false
    end
    local objectsInObj = obj.getObjects()
    local cardTags 
    for i, v in ipairs(objectsInObj) do
        cardTags = getTags(v.description,"#")
        for j, w in ipairs(cardTags) do
            if getCardTypeFromSingleTag(w) ~= false then
                --Basically there is a playing card which we think
                --is part of the main deck in this deck
                m_objMainDeck = obj
                m_bNeedRecovery = false
                printToAll("Found the deck! Thank you. Clicking too quickly can cause me to lose it.")
                return true
            end
        end
    end
    return false
end

function getNextFreeHazzardPlacementObject()
    -- Only the Hazzard placement tags are 19 -23 inc
    local idOfFreeHazzard = 20 + m_iNumberOfHazzardsOutOfDeck
    local nextFreeHazzard = getObjectFromGUID(m_tbGUIDinDescription[idOfFreeHazzard])
    if idOfFreeHazzard < 20 or idOfFreeHazzard > 24 then
        printToAll("nextFreeHazzard is out of bounds: " .. m_iNumberOfHazzardsOutOfDeck)
    elseif nextFreeHazzard == nil then
        printToAll("Could not find next free Hazzard: " .. m_iNumberOfHazzardsOutOfDeck)
        return false
    end
    return nextFreeHazzard
end

function getCardTypeFromSingleTag(cardType)
    --Inputs:
    --cardType:	string
    --      The tag with a card type
    --Outputs:
    --fail | bool: false
    --      Colour not changed
    --success | bool: true
    --      Colour changed
    if cardType == "" then
        return false
    elseif cardType == "#hazard" then
        return "hazard"
    elseif cardType == "#gem" then
        return "gem"
    elseif cardType == "#artifact" then
        return "artifact"
    end
    return false
end

function getTags(description, requiredElement)
    --Inputs:
    --description:	string
    --      A string with #tags delimited by spaces
    --requiredElement: string
    --      The prefix required to count the tag.
    --      Blank means no tag
    --Outputs:
    --fail | bool: false
    --      There were no tags
    --success | table: values
    --      The values found
    if description == "" then
        return false
    end
    _stringSplit = string.gmatch(description, "%S+")
    _returnArray = {}
    _numberOfElements = 1
    for tag in _stringSplit do
        if tag ~= nil and requiredElement ~= nil then
            if requiredElement == "" then
                _returnArray[_numberOfElements] = tag
                _numberOfElements = _numberOfElements + 1
                --print(tag)
            elseif string.len(tag) > string.len(requiredElement) then
                if string.sub(tag,1,string.len(requiredElement)) ==    requiredElement then
                    --print(tag)
                    _returnArray[_numberOfElements] = tag
                    _numberOfElements = _numberOfElements + 1
                end
            end
        end
    end
    if _numberOfElements == 1 then
        return false
    end
    return _returnArray
end

function createMainButton()
    local button_parameters = {}

    button_parameters.click_function = "mainButton"
    button_parameters.function_owner = self
    button_parameters.position = {0,0,-21}
    button_parameters.label = "Deal"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnDeal = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function createShowHideButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleDeckVisibility"
    button_parameters.function_owner = self
    button_parameters.position = {-5.6,0,-21}
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnShowHideButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function createSmoothMovementButton()
    local button_parameters = {}
    
    button_parameters.click_function = "toggleSmoothMovement"
    button_parameters.function_owner = self
    button_parameters.position = {-5.6,0,-24}
    button_parameters.label = "Show/Hide"
    button_parameters.width = 2000
    button_parameters.height = 800
    button_parameters.font_size = 240
    
    self.createButton(button_parameters)
    --Set reference
    m_iBtnSmoothMovementButton = m_btnNumberOfButtons
    m_btnNumberOfButtons = m_btnNumberOfButtons + 1
end

function setupDebugTimer()
    timerID = self.getGUID()..math.random(9999999999999)
    --Start timer which repeats forever, running countItems() every second
    Timer.create({
        identifier=timerID,
        function_name="findItemsWhereMainDeckShouldBe", function_owner=self,
        repetitions=0, delay=1
    })
end

function findDeckUsingCollider()
    local objects = findItemsWhereMainDeckShouldBe()
    for _, entry in ipairs(objects) do
        if deckRecovery(entry.hit_object) then
            return true
        end
    end
    return false
end

function findItemsWhereMainDeckShouldBe()
    --Find scaling factor
    local scale = self.getScale()
    --Set position for the sphere
    local pos = self.getPosition()
    pos.z = pos.z + 22.5
    pos.x = pos.x + 5.5
    pos.y=pos.y+(1.25*scale.y)
    --Ray trace to get all objects
    return Physics.cast({
        origin=pos, direction={0,1,0}, type=2, max_distance=0,
        size={5*scale.x,7.4*scale.y,5.4*scale.z}, debug=true
    })
end