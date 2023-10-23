import ballerina/io;
import ballerina/file;
import ballerina/os;
import ballerina/regex;
import ballerina/mime;
import ballerina/log;

public isolated function appendStringToFile(string line, string pathName) returns boolean {
    string fileContent = string:'join("\n", readFile(pathName), line);
    return writeFileOut(fileContent, pathName);
}

public isolated function writeFileOut(string fileContent, string pathName) returns boolean {
    io:Error? fileWriteString = io:fileWriteString(pathName, fileContent);
    return !(fileWriteString is io:Error);
}

function fileExists(string filePath) returns boolean {
    boolean|error result = file:test(filePath, file:EXISTS);
    return result is error ? false : result;
}

public function rmIfExists(string filePath) {
    boolean|error response = file:test(filePath, file:EXISTS);
    if !(response is error) && response {
        error? deleteResponse = file:remove(filePath);
    }
}

public isolated function readFile(string filePath, string joinOn = "\n") returns string {
    string output = "";
    string[]|error fileContents = io:fileReadLines(filePath);
    if fileContents is error {
        return output;
    }
    output = string:'join(joinOn, ...fileContents);
    return output;
}

public function fileRead(string filePath) returns string {
    string|error output = io:fileReadString(filePath);
    return output is error ? "" : output;
}

public function bash(string arguments) returns ExeOut {
    return run("bash", arguments);
}

public type ExeOut record {
    int exitCode;
    string output;
    string? success;
    string? failure;
};

public function run(string cmd, string arguments) returns ExeOut {
    ExeOut output = {
        "exitCode": -1,
        "output": "",
        "success": (),
        "failure": ()
    };
    //https://ballerina.io/spec/os/
    os:Process|os:Error process = os:exec({value: cmd, arguments: regex:split(arguments, " ")});
    if process is error {
        output.output = process.message();
        output.failure = process.message();
    } else {
        byte[]|error success = process.output(io:stdout);
        byte[]|error failure = process.output(io:stderr);
        int|error exitCode = process.waitForExit();

        output.success = success is error ? () : success.toString();
        output.failure = failure is error ? () : failure.toString();
        output.output = output.success ?: output.failure ?: "";
        output.exitCode = exitCode is error ? -1 : exitCode;
    }
    return output;
}

public function pyrun(string cmd) returns ExeOut {
    return run("python3", cmd);
}

public function fileToBase64(string filePath) returns string {
    do {
        return <string>check mime:base64Encode(check io:fileReadString(filePath));
    } on fail var e {
        log:printError({errorMsg: e.message()}.toJsonString());
        return "";
    }
}
