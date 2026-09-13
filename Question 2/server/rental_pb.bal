import ballerina/grpc;
import ballerina/protobuf;

public const string RENTAL_DESC = "0A0C72656E74616C2E70726F746F120672656E74616C2287020A0850726F7065727479121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A07686F73745F69641802200128095206686F7374496412120A046E616D6518032001280952046E616D65121A0A086C6F636174696F6E18042001280952086C6F636174696F6E12390A0D70726F70657274795F7479706518052001280E32142E72656E74616C2E50726F706572747954797065520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180620012801520D70726963655065724E69676874122E0A0673746174757318072001280E32162E72656E74616C2E50726F7065727479537461747573520673746174757322E9010A0B4E657750726F706572747912170A07686F73745F69641801200128095206686F7374496412120A046E616D6518022001280952046E616D65121A0A086C6F636174696F6E18032001280952086C6F636174696F6E12390A0D70726F70657274795F7479706518042001280E32142E72656E74616C2E50726F706572747954797065520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180520012801520D70726963655065724E69676874122E0A0673746174757318062001280E32162E72656E74616C2E50726F70657274795374617475735206737461747573222D0A0A50726F70657274794964121F0A0B70726F70657274795F6964180120012809520A70726F706572747949642294020A1555706461746550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A07686F73745F69641802200128095206686F7374496412120A046E616D6518032001280952046E616D65121A0A086C6F636174696F6E18042001280952086C6F636174696F6E12390A0D70726F70657274795F7479706518052001280E32142E72656E74616C2E50726F706572747954797065520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180620012801520D70726963655065724E69676874122E0A0673746174757318072001280E32162E72656E74616C2E50726F7065727479537461747573520673746174757322510A1552656D6F766550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A07686F73745F69641802200128095206686F7374496422400A0C50726F70657274794C69737412300A0A70726F7065727469657318012003280B32102E72656E74616C2E50726F7065727479520A70726F7065727469657322660A0E50726F706572747946696C746572121A0A086C6F636174696F6E18012001280952086C6F636174696F6E121B0A096D696E5F707269636518022001280152086D696E5072696365121B0A096D61785F707269636518032001280152086D6178507269636522300A0D53656172636852657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496422760A0E536561726368526573706F6E7365121C0A09617661696C61626C651801200128085209617661696C61626C6512180A076D65737361676518022001280952076D657373616765122C0A0870726F706572747918032001280B32102E72656E74616C2E50726F7065727479520870726F706572747922760A0B5573657250726F66696C6512170A07757365725F6964180120012809520675736572496412120A046E616D6518022001280952046E616D6512140A05656D61696C1803200128095205656D61696C12240A04726F6C6518042001280E32102E72656E74616C2E55736572526F6C655204726F6C65226D0A0C436F6E6669726D6174696F6E12180A077375636365737318012001280852077375636365737312290A1075736572735F72656769737465726564180220012805520F75736572735265676973746572656412180A076D65737361676518032001280952076D6573736167652284010A0E426F6F6B696E675265717565737412190A0867756573745F6964180120012809520767756573744964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496412190A08636865636B5F696E1803200128095207636865636B496E121B0A09636865636B5F6F75741804200128095208636865636B4F757422670A10426F6F6B696E6743617274456E747279121D0A0A626F6F6B696E675F69641801200128095209626F6F6B696E674964121A0A0861636365707465641802200128085208616363657074656412180A076D65737361676518032001280952076D65737361676522360A15436F6E6669726D426F6F6B696E6752657175657374121D0A0A626F6F6B696E675F69641801200128095209626F6F6B696E67496422C0010A13426F6F6B696E67436F6E6669726D6174696F6E12180A0773756363657373180120012808520773756363657373121D0A0A626F6F6B696E675F69641802200128095209626F6F6B696E674964121F0A0B70726F70657274795F6964180320012809520A70726F7065727479496412160A066E696768747318042001280552066E6967687473121D0A0A746F74616C5F636F73741805200128015209746F74616C436F737412180A076D65737361676518062001280952076D6573736167652A670A0C50726F706572747954797065121D0A1950524F50455254595F545950455F554E5350454349464945441000120D0A0941504152544D454E54100112090A05484F555345100212080A04524F4F4D100312090A0556494C4C41100412090A054C4F44474510052A5A0A0E50726F7065727479537461747573121F0A1B50524F50455254595F5354415455535F554E5350454349464945441000120D0A09415641494C41424C451001120A0A06424F4F4B45441002120C0A08494E41435449564510032A3A0A0855736572526F6C6512190A15555345525F524F4C455F554E535045434946494544100012080A04484F5354100112090A054755455354100232AE040A0D52656E74616C5365727669636512370A0C6164645F70726F706572747912132E72656E74616C2E4E657750726F70657274791A122E72656E74616C2E50726F70657274794964123B0A0C6372656174655F757365727312132E72656E74616C2E5573657250726F66696C651A142E72656E74616C2E436F6E6669726D6174696F6E280112420A0F7570646174655F70726F7065727479121D2E72656E74616C2E55706461746550726F7065727479526571756573741A102E72656E74616C2E50726F706572747912460A0F72656D6F76655F70726F7065727479121D2E72656E74616C2E52656D6F766550726F7065727479526571756573741A142E72656E74616C2E50726F70657274794C69737412470A196C6973745F617661696C61626C655F70726F7065727469657312162E72656E74616C2E50726F706572747946696C7465721A102E72656E74616C2E50726F7065727479300112400A0F7365617263685F70726F706572747912152E72656E74616C2E536561726368526571756573741A162E72656E74616C2E536561726368526573706F6E736512410A0D626F6F6B5F70726F706572747912162E72656E74616C2E426F6F6B696E67526571756573741A182E72656E74616C2E426F6F6B696E6743617274456E747279124D0A0F636F6E6669726D5F626F6F6B696E67121D2E72656E74616C2E436F6E6669726D426F6F6B696E67526571756573741A1B2E72656E74616C2E426F6F6B696E67436F6E6669726D6174696F6E620670726F746F33";

public isolated client class RentalServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, RENTAL_DESC);
    }

    isolated remote function add_property(NewProperty|ContextNewProperty req) returns PropertyId|grpc:Error {
        map<string|string[]> headers = {};
        NewProperty message;
        if req is ContextNewProperty {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/add_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyId>result;
    }

    isolated remote function add_propertyContext(NewProperty|ContextNewProperty req) returns ContextPropertyId|grpc:Error {
        map<string|string[]> headers = {};
        NewProperty message;
        if req is ContextNewProperty {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/add_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyId>result, headers: respHeaders};
    }

    isolated remote function update_property(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns Property|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/update_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <Property>result;
    }

    isolated remote function update_propertyContext(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns ContextProperty|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/update_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <Property>result, headers: respHeaders};
    }

    isolated remote function remove_property(RemovePropertyRequest|ContextRemovePropertyRequest req) returns PropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/remove_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyList>result;
    }

    isolated remote function remove_propertyContext(RemovePropertyRequest|ContextRemovePropertyRequest req) returns ContextPropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/remove_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyList>result, headers: respHeaders};
    }

    isolated remote function search_property(SearchRequest|ContextSearchRequest req) returns SearchResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchRequest message;
        if req is ContextSearchRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/search_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SearchResponse>result;
    }

    isolated remote function search_propertyContext(SearchRequest|ContextSearchRequest req) returns ContextSearchResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchRequest message;
        if req is ContextSearchRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/search_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SearchResponse>result, headers: respHeaders};
    }

    isolated remote function book_property(BookingRequest|ContextBookingRequest req) returns BookingCartEntry|grpc:Error {
        map<string|string[]> headers = {};
        BookingRequest message;
        if req is ContextBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/book_property", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookingCartEntry>result;
    }

    isolated remote function book_propertyContext(BookingRequest|ContextBookingRequest req) returns ContextBookingCartEntry|grpc:Error {
        map<string|string[]> headers = {};
        BookingRequest message;
        if req is ContextBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/book_property", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookingCartEntry>result, headers: respHeaders};
    }

    isolated remote function confirm_booking(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns BookingConfirmation|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirm_booking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookingConfirmation>result;
    }

    isolated remote function confirm_bookingContext(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ContextBookingConfirmation|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirm_booking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookingConfirmation>result, headers: respHeaders};
    }

    isolated remote function create_users() returns Create_usersStreamingClient|grpc:Error {
        grpc:StreamingClient sClient = check self.grpcClient->executeClientStreaming("rental.RentalService/create_users");
        return new Create_usersStreamingClient(sClient);
    }

    isolated remote function list_available_properties(PropertyFilter|ContextPropertyFilter req) returns stream<Property, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        PropertyFilter message;
        if req is ContextPropertyFilter {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/list_available_properties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return new stream<Property, grpc:Error?>(outputStream);
    }

    isolated remote function list_available_propertiesContext(PropertyFilter|ContextPropertyFilter req) returns ContextPropertyStream|grpc:Error {
        map<string|string[]> headers = {};
        PropertyFilter message;
        if req is ContextPropertyFilter {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/list_available_properties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        PropertyStream outputStream = new PropertyStream(result);
        return {content: new stream<Property, grpc:Error?>(outputStream), headers: respHeaders};
    }
}

public isolated client class Create_usersStreamingClient {
    private final grpc:StreamingClient sClient;

    isolated function init(grpc:StreamingClient sClient) {
        self.sClient = sClient;
    }

    isolated remote function sendUserProfile(UserProfile message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function sendContextUserProfile(ContextUserProfile message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function receiveConfirmation() returns Confirmation|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, _] = response;
            return <Confirmation>payload;
        }
    }

    isolated remote function receiveContextConfirmation() returns ContextConfirmation|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, headers] = response;
            return {content: <Confirmation>payload, headers: headers};
        }
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.sClient->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.sClient->complete();
    }
}

public class PropertyStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|Property value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|Property value;|} nextRecord = {value: <Property>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public isolated client class RentalServicePropertyListCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendPropertyList(PropertyList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextPropertyList(ContextPropertyList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServicePropertyIdCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendPropertyId(PropertyId response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextPropertyId(ContextPropertyId response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceBookingConfirmationCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBookingConfirmation(BookingConfirmation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBookingConfirmation(ContextBookingConfirmation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceSearchResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSearchResponse(SearchResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSearchResponse(ContextSearchResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceBookingCartEntryCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendBookingCartEntry(BookingCartEntry response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextBookingCartEntry(ContextBookingCartEntry response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServiceConfirmationCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendConfirmation(Confirmation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextConfirmation(ContextConfirmation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class RentalServicePropertyCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendProperty(Property response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextProperty(ContextProperty response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public type ContextUserProfileStream record {|
    stream<UserProfile, error?> content;
    map<string|string[]> headers;
|};

public type ContextPropertyStream record {|
    stream<Property, error?> content;
    map<string|string[]> headers;
|};

public type ContextSearchRequest record {|
    SearchRequest content;
    map<string|string[]> headers;
|};

public type ContextUserProfile record {|
    UserProfile content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyRequest record {|
    UpdatePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextNewProperty record {|
    NewProperty content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingRequest record {|
    ConfirmBookingRequest content;
    map<string|string[]> headers;
|};

public type ContextPropertyId record {|
    PropertyId content;
    map<string|string[]> headers;
|};

public type ContextSearchResponse record {|
    SearchResponse content;
    map<string|string[]> headers;
|};

public type ContextPropertyList record {|
    PropertyList content;
    map<string|string[]> headers;
|};

public type ContextBookingRequest record {|
    BookingRequest content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyRequest record {|
    RemovePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextBookingCartEntry record {|
    BookingCartEntry content;
    map<string|string[]> headers;
|};

public type ContextBookingConfirmation record {|
    BookingConfirmation content;
    map<string|string[]> headers;
|};

public type ContextPropertyFilter record {|
    PropertyFilter content;
    map<string|string[]> headers;
|};

public type ContextConfirmation record {|
    Confirmation content;
    map<string|string[]> headers;
|};

public type ContextProperty record {|
    Property content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UpdatePropertyRequest record {|
    string property_id = "";
    string host_id = "";
    string name = "";
    string location = "";
    PropertyType property_type = PROPERTY_TYPE_UNSPECIFIED;
    float price_per_night = 0.0;
    PropertyStatus status = PROPERTY_STATUS_UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UserProfile record {|
    string user_id = "";
    string name = "";
    string email = "";
    UserRole role = USER_ROLE_UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type NewProperty record {|
    string host_id = "";
    string name = "";
    string location = "";
    PropertyType property_type = PROPERTY_TYPE_UNSPECIFIED;
    float price_per_night = 0.0;
    PropertyStatus status = PROPERTY_STATUS_UNSPECIFIED;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ConfirmBookingRequest record {|
    string booking_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type PropertyId record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchResponse record {|
    boolean available = false;
    string message = "";
    Property property = {};
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type PropertyList record {|
    Property[] properties = [];
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookingRequest record {|
    string guest_id = "";
    string property_id = "";
    string check_in = "";
    string check_out = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemovePropertyRequest record {|
    string property_id = "";
    string host_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookingCartEntry record {|
    string booking_id = "";
    boolean accepted = false;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookingConfirmation record {|
    boolean success = false;
    string booking_id = "";
    string property_id = "";
    int nights = 0;
    float total_cost = 0.0;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type PropertyFilter record {|
    string location = "";
    float min_price = 0.0;
    float max_price = 0.0;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type Confirmation record {|
    boolean success = false;
    int users_registered = 0;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type Property record {|
    string property_id = "";
    string host_id = "";
    string name = "";
    string location = "";
    PropertyType property_type = PROPERTY_TYPE_UNSPECIFIED;
    float price_per_night = 0.0;
    PropertyStatus status = PROPERTY_STATUS_UNSPECIFIED;
|};

public enum PropertyType {
    PROPERTY_TYPE_UNSPECIFIED, APARTMENT, HOUSE, ROOM, VILLA, LODGE
}

public enum PropertyStatus {
    PROPERTY_STATUS_UNSPECIFIED, AVAILABLE, BOOKED, INACTIVE
}

public enum UserRole {
    USER_ROLE_UNSPECIFIED, HOST, GUEST
}
