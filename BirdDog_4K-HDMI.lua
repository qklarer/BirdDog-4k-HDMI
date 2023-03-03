local json             = require('json')
local Decoder          = NamedControl.GetValue("Decoder") + 1
local decoderState     = nil
local gotData          = false
local Rebooting        = false
local screenSaver      = NamedControl.GetPosition("screenSaver")
local screenSaverState = nil
local Operation        = NamedControl.GetValue("Operation")
local operationState   = nil
local Mode             = nil
local Version          = nil
local gotResponse      = false
local rebootTimer      = 0
local dataTimer        = 0
local responseTimer    = 0

local Encoders = {
    [1] = NamedControl.GetText("enc1"),
    [2] = NamedControl.GetText("enc2"),
    [3] = NamedControl.GetText("enc3"),
    [4] = NamedControl.GetText("enc4"),
    [5] = NamedControl.GetText("enc5"),
    [6] = NamedControl.GetText("enc6"),
    [7] = NamedControl.GetText("enc7"),
    [8] = NamedControl.GetText("enc8"),
    [9] = NamedControl.GetText("enc9"),
    [10] = NamedControl.GetText("enc10")
}

NamedControl.SetText("hostName", "")
NamedControl.SetText("connectedTo", "")
NamedControl.SetText("Mode", "")
NamedControl.SetText("Version", "")
NamedControl.SetText("Response", "")
NamedControl.SetText("Format", "")
NamedControl.SetText("Serial", "")

function Response()

end

function Initiate()


    local IP = NamedControl.GetText("IP")

    function AboutResponse(Table, ReturnCode, Data, Error, Headers)

        local decodedJson = json.decode(Data)

        if ReturnCode == 200 then
            NamedControl.SetText("Serial", decodedJson.SerialNumber)
            NamedControl.SetText("Format", decodedJson.Format)
        end
    end

    function About()

        HttpClient.Upload({
            Url = IP .. ":8080/about",
            Headers = { ["Accept"] = "text" },
            Data = "",
            Method = "GET",
            EventHandler = AboutResponse
        })
    end

    function HostName_RequestResponse(Table, ReturnCode, Data, Error, Headers)
        if ReturnCode == 200 then
            NamedControl.SetText("hostName", Data)
            gotData = true
            Rebooting = false
            Connected = true

        end
    end

    function HostName_Request()

        HttpClient.Upload({
            Url = IP .. ":8080/hostname",
            Headers = { ["Accept"] = "text" },
            Data = "",
            Method = "GET",
            EventHandler = HostName_RequestResponse
        })
    end

    function GetModeResponse(Table, ReturnCode, Data, Error, Headers)

        function CheckMode()

            local decodedJson = json.decode(Data)
            return decodedJson.mode
        end

        if pcall(CheckMode) then
            NamedControl.SetText("Mode", CheckMode())
            Mode = CheckMode()
        elseif Data == "encode" then
            NamedControl.SetText("Mode", "encode")
        elseif Data == "decode" then
            NamedControl.SetText("Mode", "decode")
        else
            NamedControl.SetText("Mode", "N/A")
        end

    end

    function GetMode()

        HttpClient.Upload({
            Url = IP .. ":8080/operationmode",
            Headers = { ["Content-Type"] = "application/json" },
            Data = "",
            Method = "GET",
            EventHandler = GetModeResponse
        })
    end

    function GetVersionResponse(Table, ReturnCode, Data, Error, Headers)

        NamedControl.SetText("Version", Data)
    end

    function GetVersion()

        HttpClient.Upload({
            Url = IP .. ":8080/version",
            Headers = { ["Content-Type"] = "application/json" },
            Data = "",
            Method = "GET",
            EventHandler = GetVersionResponse
        })
    end

    function ConnectedToResponse(Table, ReturnCode, Data, Error, Headers)

        local decodedJson = json.decode(Data)
        NamedControl.SetText("connectedTo", decodedJson.sourceName)
    end

    function ConnectedTo()

        HttpClient.Upload({
            Url = IP .. ":8080/connectTo",
            Headers = { ["Content-Type"] = "application/json" },
            Data = "",
            Method = "GET",
            EventHandler = ConnectedToResponse
        })
    end

    function GetDecoderResponse(Table, ReturnCode, Data, Error, Headers)

        print(Data)
        local decodedJson = json.decode(Data)
    end

    function GetDecoder()

        HttpClient.Upload({
            Url = IP .. ":8080/decodestatus",
            Headers = { ["Content-Accept"] = "text" },
            Data = "",
            Method = "GET",
            EventHandler = GetDecoderResponse
        })
    end

    About()
    HostName_Request()
    GetMode()
    GetVersion()

    if Mode == "decoder" then
        ConnectedTo()
    end
    --GetList()
    GetDecoder()
end

--------------------------------------------------------------------------------------------------------------------------------

function ChangeRouteResponse(Table, ReturnCode, Data, Error, Headers)

    if Data == "success" then
        NamedControl.SetText("Response", "Success")
        gotResponse = true
        ConnectedTo()
    end
    if ReturnCode == 200 then
        gotData = true
    end
end

function ChangeRoute(encoderChange)

    for i = 1, 10 do
        if encoderChange == i then
            Controls.Outputs[i].Value = i
        else Controls.Outputs[i].Value = 0
        end
    end
    encoderChange = Encoders[encoderChange]

    local encodedData = json.encode({ sourceName = encoderChange, port = "5962" })

    HttpClient.Upload({
        Url = NamedControl.GetText("IP") .. ":8080/connectTO",
        Headers = { ["Content-Type"] = "application/json" },
        Data = encodedData,
        Method = "POST",
        EventHandler = ChangeRouteResponse
    })
end

function RefreshResponse(Table, ReturnCode, Data, Error, Headers)

    if ReturnCode == 200 then
        gotData = true
    end
end

function Refresh()

    HttpClient.Upload({
        Url = NamedControl.GetText("IP") .. ":8080/reset",
        Headers = { ["Accept"] = "text" },
        Data = "",
        Method = "GET",
        EventHandler = RefreshResponse
    })
end

function RebootResponse(Table, ReturnCode, Data, Error, Headers)

    if ReturnCode == 200 then
        gotData = true
    end
end

function Reboot(State)

    HttpClient.Upload({
        Url = NamedControl.GetText("IP") .. ":8080/" .. State,
        Headers = { ["Accept"] = "text" },
        Data = "",
        Method = "GET",
        EventHandler = RebootResponse
    })

    Rebooting = true
end

-- function ChangeOperationResponse(Table, ReturnCode, Data, Error, Headers)

--     if ReturnCode == 200 then
--         gotData = true
--     end
-- end

-- function ChangeOperation(State)

--     if State == 0 then
--         State = "encode"
--     elseif State == 1 then
--         State = "decode"
--     end

--     local encodedJson = json.encode({ mode = State })
--     HttpClient.Upload({
--         Url = NamedControl.GetText("IP") .. ":8080/operationmode",
--         Headers = { ["Content-Type"] = "application/json" },
--         Data = encodedJson,
--         Method = "POST",
--         EventHandler = ChangeOperationResponse
--     })
-- end

function TimerClick()

    Decoder = NamedControl.GetValue("Decoder") + 1

    if NamedControl.GetPosition("Connect") == 1 then
        Initiate()
        NamedControl.SetPosition("Connect", 0)
    end

    if Rebooting then
        NamedControl.SetText("Response", "Rebooting...")
        rebootTimer = rebootTimer + 1
        if rebootTimer == 175 then
            Rebooting = false
            rebootTimer = 0
            NamedControl.SetText("Response", "")
            Initiate()
        end
    end

    if gotData then
        dataTimer = dataTimer + 1
        NamedControl.SetPosition("DataLed", 1)

        if dataTimer == 8 then
            gotData = false
            dataTimer = 0
            NamedControl.SetPosition("DataLed", 0)
        end
    end

    if gotResponse then
        responseTimer = responseTimer + 1
        if responseTimer == 8 then
            gotResponse = false
            responseTimer = 0
            NamedControl.SetText("Response", "")
        end
    end
    --------------------------------------------------------------------
    if Connected and not Rebooting then

        --screenSaver = NamedControl.GetPosition("screenSaver")
        Operation = NamedControl.GetValue("Operation")

        if Mode == "decode" then
            NamedControl.SetText("allowRoute", "Encoders")
            if decoderState ~= Decoder then
                ChangeRoute(Decoder)
                decoderState = Decoder
            end
        else NamedControl.SetText("allowRoute", "Connected Device Is Not A Decoder")
        end

        if NamedControl.GetPosition("Reboot") == 1 then
            Reboot("Reboot")
            NamedControl.SetPosition("Reboot", 0)
        end
        if NamedControl.GetPosition("Restart") == 1 then
            Reboot("Restart")
            NamedControl.SetPosition("Restart", 0)
        end
        if NamedControl.GetPosition("Refresh") == 1 then
            Refresh()
            NamedControl.SetPosition("Refresh", 0)
        end
        -- if screenSaverState ~= screenSaver then
        --     SetScreenSaver(screenSaver)
        --     screenSaverState = screenSaver
        -- end

        -- if Operation ~= operationState then
        --     ChangeOperation(Operation)
        --     NamedControl.SetText("Response", "It Is Recommended To Restart The Device")
        --     gotResponse = true
        --     operationState = Operation
        -- end
    end


end

MyTimer = Timer.New()
MyTimer.EventHandler = TimerClick
MyTimer:Start(.25)




-- function GetListResponse(Table, ReturnCode, Data, Error, Headers)

--     local decodedJson = json.decode(Data)
-- end

-- function GetList()

--     HttpClient.Upload({
--         Url = IP .. ":8080/List",
--         Headers = { ["Content-Type"] = "application/json" },
--         Data = "",
--         Method = "GET",
--         EventHandler = GetListResponse
--     })
-- end

-- function GetDecoderResponse(Table, ReturnCode, Data, Error, Headers)

--     local decodedJson = json.decode(Data)
-- end

-- function GetDecoder()

--     HttpClient.Upload({
--         Url = IP .. ":8080/decodestatus",
--         Headers = { ["Content-Accept"] = "text" },
--         Data = "",
--         Method = "GET",
--         EventHandler = GetDecoderResponse
--     })
-- end


-- function SetScreenSaverResponse(Table, ReturnCode, Data, Error, Headers)

--     print(Data)
--     print(Table)
--     print(ReturnCode)
--     print(Error)
--     print(Headers)
--     if ReturnCode == 200 then
--         gotData = true
--     end
-- end

-- function SetScreenSaver(State)

--     if State == 1 then
--         State = "Off"
--     elseif State == 0 then
--         State = "On"
--     end

--     local encodedJson = json.encode({ StreamToNetwork = State })

--     HttpClient.Upload({
--         Url = NamedControl.GetText("IP") .. ":8080/encodesetup?",
--         Headers = { ["Content-Type"] = "application/json" },
--         Data = encodedJson,
--         Method = "POST",
--         EventHandler = SetScreenSaverResponse
--     })
-- end
