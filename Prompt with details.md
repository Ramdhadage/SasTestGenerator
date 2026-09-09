*I would like to create a R package which allow the importing the sas macro code and functional requirements documents and based on frd andacro.code block it should generate the test cases and along with sas code with sample data. All should happen in R only. THis should be simple R package that can read SAS macro code and functional requirements documents (FRD), and then generate test cases along with SAS code and sample data. Below is a simple outline of how you can structure your R package to achieve this functionality

## Feature architecture:

```mermaid
graph TD
    User --> Upload_FRD[Upload FRD]
    Upload_FRD --> Upload_Macro[Upload Macro]
    Upload_Macro --> AI_Model[AI Model]
    AI_Model --> Prompt_Version[Prompt Version]
    Prompt_Version --> Model_Version[Model Version]
    Model_Version --> Generated_Test_Cases[Generated Test Cases]
    Generated_Test_Cases --> User_Review[User Review]
    User_Review --> Approved_Test_Cases[Approved Test Cases]
```
## Full Architecture

```mermaid
graph TD
    %% Node Definitions
    App["R Package<br>Test Case Generator"]
    
    FRD["Upload FRD<br>PDF/DOCX/TXT"]
    Macro["Upload SAS Macro<br>.sas"]
    
    Parser["R Document<br>Parser"]
    Analyzer["SAS Macro<br>Analyzer"]
    Engine["LLM / AI<br>Engine"]
    
    TC["Test Cases"]
    SD["Sample Data"]
    SC["SAS Code"]
    
    Trace["Traceability<br>FRD ➔ Macro ➔<br>Test Case"]
    
    Output["Excel / CSV / SAS"]

    %% Process Connections
    App --> FRD
    App --> Macro
    
    FRD --> Parser
    Macro --> Parser
    
    Parser --> Analyzer
    Analyzer --> Engine
    
    Engine --> TC
    Engine --> SD
    Engine --> SC
    
    TC --> Trace
    SD --> Trace
    SC --> Trace
    
    Trace --> Output

    %% Custom Styling
    style App fill:#f9f9f9,stroke:#333,stroke-width:2px
    style Parser fill:#f9f9f9,stroke:#333,stroke-width:2px
    style Analyzer fill:#f9f9f9,stroke:#333,stroke-width:2px
    style Engine fill:#f9f9f9,stroke:#333,stroke-width:2px
    style Trace fill:#f9f9f9,stroke:#333,stroke-width:2px
```

##  System Prompt for ellmer:
You are a Senior SAS Programmer and Clinical Programming
Validation Expert.

Analyze the Functional Requirements Document and SAS Macro.

Your objective is to generate comprehensive test cases that
validate whether the SAS macro satisfies the functional
requirements.

Analyze:

1. Functional requirements
2. Macro parameters
3. Macro variables
4. DATA step logic
5. IF/ELSE conditions
6. WHERE conditions
7. PROC SQL logic
8. SAS functions
9. Loops
10. %IF/%ELSE
11. %DO loops
12. Dynamic code generation
13. Dataset inputs/outputs
14. Variable creation
15. Variable modification
16. Missing values
17. Boundary conditions
18. Invalid inputs
19. Duplicate records
20. Data type issues

For every requirement generate:

- Requirement ID
- Test Case ID
- Test Scenario
- Test Objective
- Input Variables
- Input Values
- Expected Output
- Expected Result
- Test Type
- SAS Test Code
- Traceability

Test types should include:

POSITIVE
NEGATIVE
BOUNDARY
MISSING VALUE
DATA TYPE
DUPLICATE
PARAMETER
ERROR HANDLING

Return the result as structured JSON.

## Example

### FRD

If parameter is ALT and value is greater than 3 × ULN, derive toxicity flag = Y.
### SAS macro
```sas
%macro derive_flag(
    input=,
    output=
);

data &output;
    set &input;

    if PARAM = "ALT" and VALUE > 3*ULN then
        TOXFL = "Y";
    else
        TOXFL = "N";

run;

%mend;
```
### Logic
R package automatically identifies:
```mermaid
 graph TD
    FRD[FRD Requirement] --> PARAM[PARAM = ALT<br>VALUE > 3 × ULN]
    PARAM --> SAS[SAS Macro Logic]
    SAS --> Test[Test conditions]
    
    Test --> C1[ALT + VALUE > 3 × ULN]
    Test --> C2[ALT + VALUE = 3 × ULN]
    Test --> C3[ALT + VALUE < 3 × ULN]
    Test --> C4[Different PARAM]
    Test --> C5[Missing VALUE]
    Test --> C6[Missing ULN]
    Test --> C7[Missing PARAM]
```
### Test cases
Then it shuold generate the following test cases:

| ID    | Type     | Scenario           | Expected |
| ----- | -------- | ------------------ | -------- |
| TC001 | Positive | ALT > 3×ULN        | Y        |
| TC002 | Boundary | ALT = 3×ULN        | N        |
| TC003 | Negative | ALT < 3×ULN        | N        |
| TC004 | Negative | AST instead of ALT | N        |
| TC005 | Missing  | VALUE missing      | N        |
| TC006 | Missing  | ULN missing        | N        |
### SAS test data
And generate SAS test data:
```sas
data test_input;
    input USUBJID $ PARAM $ VALUE ULN;
datalines;
SUBJ001 ALT 350 100
SUBJ002 ALT 300 100
SUBJ003 ALT 250 100
SUBJ004 AST 350 100
SUBJ005 ALT .   100
;
run;
```
### Validation code
Then generate validation code:
```sas  
%derive_trtemfl(
    in=test_input,
    out=test_output
);

proc print data=test_output;
run;
```
## constraints
1. This is poc with less efforts, no test cases please and with minimum code.
2. Use skills like [cli](C:\\Users\\admin\\.codex\\skills\\cli\\SKILL.md), [tidy-r](C:\\Users\\admin\\.agents\\skills\\tidy-r\\SKILL.md),  [r-package-development](C:\\Users\\admin\\.codex\\skills\\r-package-development\\SKILL.md) and functional programming and good coding practices. 
3. The R package should be able to read and parse SAS macro code and functional requirements documents
4. Just focus on generating test cases and SAS code with sample data based on the FRD and SAS macro code. 
5. The package should be simple and user-friendly, allowing users to easily upload their FRD and SAS macro code, and receive the generated test cases and SAS code with sample data in a structured format.
# Coding Architecture structure:

```mermaid
graph TD
    %% Custom Styling
    classDef complex fill:#f9d5e5,stroke:#333,stroke-width:2px;
    classDef intermediate fill:#eeeeff,stroke:#333,stroke-width:2px;
    classDef simple fill:#d4edda,stroke:#333,stroke-width:2px;

    %% Level 3: Simple & User Friendly (Top layer)
    subgraph Level_3 [Level 3: Simple & User Friendly]
    
        C1["<b>Package Function</b><br/> Simple user-facing functions like import_sas_macro(), read_frd(), and generate_sas_tests()"]
        C2["<b>Feedback Loops</b><br/>  Integration of cli or progressr packages to show clear text formatting, execution steps, and progress bars while the AI processes the files."]
       
    end
    class C1,C2 simple;

    %% Level 2: Intermediate Logic (Middle layer)   
    subgraph Level_2 [Level 2: Intermediate Logic]
        B1["<b>Document Parsing & Ingestion</b><br/> Internal rules to read and clean text blocks from SAS macros (.sas) and functional requirement documents"]
        B2["<b>Prompt Orchestration</b><br/> Functions that dynamically combine the parsed SAS macro text and the corresponding FRD section into a highly structured prompt context for the AI."]
        B3["<b>Output Validation</b><br/> Post-processing the AI's response to separate the generated test cases (markdown/text), the SAS testing code, and the sample datasets."]
    end
    C1 --> B1
    C2 --> B1
    C2 --> B2
    C2 --> B3
    class B1,B2 intermediate;

    %% Level 1: Complex Logic (Bottom layer)
    subgraph Level_1 [Level 1: Complex Logic]
        A1["<b>LLM / AI Integration</b><br/>The core backend connection using R packages like ellmer to securely communicate with an AI model open_router"]
        A2["<b>Deterministic Code Generation</b><br/> Highly structured prompt templates that force the AI to return data in specific formats (such as JSON or strict markdown blocks) so R can easily parse them back into usable objects."]
        A3["<b>Data Synthesis Engine</b><br/> The logic ensuring that the generated sample data matches the column types, constraints, and edge cases defined in both the FRD and the SAS macro structure."]

    end
    B1 --> A1
    B2 --> A1
    B3 --> A1
    B1 --> A2
    B2 --> A2
    B3 --> A2
    B1 --> A3
    B2 --> A3
    B3 --> A3
    class A complex;

```
This is a high-level architecture for your R package that will allow users to upload SAS macro code and functional requirements documents, and then generate test cases along with SAS code and sample data. The package will be structured in a way that is user-friendly, while also incorporating complex logic for parsing, analyzing, and generating the required outputs.*