log close _all

* Set your own data and output directories
clear all
set more off

local os : environment OS
local is_win = strpos("`os'", "Windows") > 0

* Get username
local user : environment USER
if "`user'" == "" local user : environment USERNAME  // For Windows

* Define base path depending on OS
if `is_win' {
    global proj_dir "C:/Users/`user'/Dropbox/Labor_Market_PT/replication/final" // Maybe different?
}
else {
    global proj_dir "/Users/`user'/Library/CloudStorage/Dropbox/Labor_Market_PT/replication/final"
}
global data_dir = "$proj_dir/data/raw"
global output_dir = "$proj_dir/data/processed"

preserve 
import delimited "$data_dir/dingelneiman/onet_wfh_code.csv", clear 
rename occ_code oes_occ_code 
tempfile onet_temp
save `onet_temp'
restore

use "$data_dir/atl_fed/atl_fed_wage_raw.dta", clear


* wage group 
gen wagegroup_num = real(regexs(1)) if regexm(wagegroup, "^([0-9]+)")


* Create education group based on numeric codes
gen str15 educ_group = ""
replace educ_group = "Bachelors+" if inlist(educ92, 6, 7)
replace educ_group = "Less than Bachelors" if inlist(educ92, 1, 2, 3, 4, 5)


* Create a string variable to hold the label
gen str occ_lbl = ""

* Loop through all unique values of occ and assign labels
levelsof occ, local(occs)
foreach x of local occs {
    local lbl : label peio1ocd `x'
    replace occ_lbl = "`lbl'" if occ == `x'
}

* Extract OES occupation code from label (e.g., 35-2010)
gen str oes_occ_code = ""
replace oes_occ_code = regexs(1) if regexm(occ_lbl, "([0-9]{2}-[0-9]{4})")

gen str occ_clean = regexs(1) if regexm(occ_lbl, "^(.*?)[\s\(]+[0-9]{2}-[0-9]{4}\)?$")

********* Manual Occupation Code Fix ************
*** Case 1: No Conflicting Telework Indicator between ATL and DN ***
*** Action: Choose occupation code with the closest meaning
replace oes_occ_code = "49-2093"  if occ_lbl == "Electrical and electronics repairers, industrial and utility 49-209X"
replace oes_occ_code = "39-4011"  if occ_lbl == "Embalmers and funeral attendants 39-40XX"
replace oes_occ_code = "49-9041"  if occ_lbl == "Industrial and refractory machinery mechanics 49-904X"
replace oes_occ_code = "37-2011"  if occ_lbl == "Janitors and building cleaners 31-201X" // Forcing the label defined in DingleNeiman data
replace oes_occ_code = "47-5011"  if occ_lbl == "Other extraction workers 47-50XX"
replace oes_occ_code = "53-6011"  if occ_lbl == "Other transportation workers 53-60XX"
replace oes_occ_code = "15-1131"  if occ_lbl == "Software developers, applications and systems software 15-113X"
replace oes_occ_code = "53-4041"  if occ_lbl == "Subway, streetcar, and other rail transportation workers 53-40XX"
replace oes_occ_code = "11-2021"  if occ_lbl == "Marketing and sales managers (11-2020)"
replace oes_occ_code = "13-1020"  if occ_lbl == "Purchasing agents and buyers, farm products 13-1021"
replace oes_occ_code = "13-1020"  if occ_lbl == "Wholesale and retail buyers, except farm products 13-1022"
replace oes_occ_code = "13-1020"  if occ_lbl == "Purchasing agents, except wholesale, retail, and farm products 13-1023"
replace oes_occ_code = "13-1071"  if occ_lbl == "Human resource workers 13-1070"
replace oes_occ_code = "13-2071"  if occ_lbl == "Loan counselors and officers 13-2070"
replace oes_occ_code = "15-1151"  if occ_lbl == "Computer support specialists 15-1150"
replace oes_occ_code = "15-2021"  if occ_lbl == "Miscellaneous mathematical science occupations 15-2090"
replace oes_occ_code = "17-1011"  if occ_lbl == "Architects, except naval 17-1010"
replace oes_occ_code = "17-2071"  if occ_lbl == "Electrical and electronic engineers 17-2070"
replace oes_occ_code = "17-3011"  if occ_lbl == "Drafters 17-3010"
replace oes_occ_code = "19-1041"  if occ_lbl == "Medical scientists 19-1040"
replace oes_occ_code = "19-2011"  if occ_lbl == "Astronomers and physicists 19-2010"
replace oes_occ_code = "19-2031"  if occ_lbl == "Chemists and materials scientists 19-2030"
replace oes_occ_code = "19-2041"  if occ_lbl == "Environmental scientists and geoscientists 19-2040"
replace oes_occ_code = "19-3031"  if occ_lbl == "Psychologists 19-3030"
replace oes_occ_code = "21-1021" if occ_lbl == "Social workers 21-1020"
replace oes_occ_code = "21-2011" if occ_lbl == "Religious workers, all other 21-2099"
replace oes_occ_code = "23-2091" if occ_lbl == "Miscellaneous legal support workers 23-2090"
replace oes_occ_code = "25-1011" if occ_lbl == "Postsecondary teachers 25-1000"
replace oes_occ_code = "25-2011" if occ_lbl == "Preschool and kindergarten teachers 25-2010"
replace oes_occ_code = "25-2021" if occ_lbl == "Elementary and middle school teachers 25-2020"
replace oes_occ_code = "25-2031" if occ_lbl == "Secondary school teachers 25-2030"
replace oes_occ_code = "25-2051" if occ_lbl == "Special education teachers 25-2040"
replace oes_occ_code = "25-3011" if occ_lbl == "Other teachers and instructors 25-3000"
replace oes_occ_code = "27-2031" if occ_lbl == "Dancers and choreographers 27-2030"
replace oes_occ_code = "27-2042" if occ_lbl == "Entertainers and performers, sports and related workers, all other 27-2099"
replace oes_occ_code = "27-3091" if occ_lbl == "Miscellaneous media and communication workers 27-3090"
replace oes_occ_code = "27-4011" if occ_lbl == "Broadcast and sound engineering technicians and radio operators 27-4010"
replace oes_occ_code = "29-1021" if occ_lbl == "Dentists 29-1020"
replace oes_occ_code = "29-2031" if occ_lbl == "Diagnostic related technologists and technicians 29-2030"
replace oes_occ_code = "29-2051" if occ_lbl == "Health diagnosing and treating practitioner support technicians 29-2050"
replace oes_occ_code = "29-2091" if occ_lbl == "Miscellaneous health technologists and technicians 29-2090"
replace oes_occ_code = "31-1011" if occ_lbl == "Nursing, psychiatric, and home health aides 31-1010"
replace oes_occ_code = "31-2011" if occ_lbl == "Occupational therapist assistants and aides 31-2010"
replace oes_occ_code = "31-2021" if occ_lbl == "Physical therapist assistants and aides 31-2020"
replace oes_occ_code = "33-1021" if occ_lbl == "Supervisors, protective service workers, all other 33-1099"
replace oes_occ_code = "33-2021" if occ_lbl == "Fire inspectors 33-2020"
replace oes_occ_code = "33-3011" if occ_lbl == "Bailiffs, correctional officers, and jailers 33-3010"
replace oes_occ_code = "35-3021" if occ_lbl == "Food preparation and serving related workers, all other 35-9099"
replace oes_occ_code = "37-3011" if occ_lbl == "Grounds maintenance workers 37-3010"
replace oes_occ_code = "39-3091" if occ_lbl == "Miscellaneous entertainment attendants and related workers 39-3090"
replace oes_occ_code = "39-6011" if occ_lbl == "Baggage porters, bellhops, and concierges 39-6010"
replace oes_occ_code = "39-7010" if occ_lbl == "Tour and travel guides 39-6020"
replace oes_occ_code = "39-9021" if occ_lbl == "Personal care and service workers, all other 39-9099"
replace oes_occ_code = "41-2011" if occ_lbl == "Cashiers 41-2010"
replace oes_occ_code = "41-4011" if occ_lbl == "Sales representatives, wholesale and manufacturing 41-4010"
replace oes_occ_code = "41-9091" if occ_lbl == "Sales and related workers, all other 41-9099"
replace oes_occ_code = "43-2021" if occ_lbl == "Communications equipment operators, all other 43-2099"
replace oes_occ_code = "43-3031" if occ_lbl == "Financial clerks, all other 43-3099"
replace oes_occ_code = "43-6011" if occ_lbl == "Secretaries and administrative assistants 43-6010"
replace oes_occ_code = "43-9111" if occ_lbl == "Office and administrative support workers, all other 43-9199"
replace oes_occ_code = "47-2021" if occ_lbl == "Brickmasons, blockmasons, and stonemasons 47-2020"
replace oes_occ_code = "47-2041" if occ_lbl == "Carpet, floor, and tile installers and finishers 47-2040"
replace oes_occ_code = "47-2051" if occ_lbl == "Cement masons, concrete finishers, and terrazzo workers 47-2050"
replace oes_occ_code = "47-2081" if occ_lbl == "Drywall installers, ceiling tile installers, and tapers 47-2080"
replace oes_occ_code = "47-2131" if occ_lbl == "Insulation workers 47-2130"
replace oes_occ_code = "47-2151" if occ_lbl == "Pipelayers, plumbers, pipefitters, and steamfitters 47-2150"
replace oes_occ_code = "47-3011" if occ_lbl == "Helpers, construction trades 47-3010"
replace oes_occ_code = "47-5011" if occ_lbl == "Derrick, rotary drill, and service unit operators, oil, gas, and mining 47-5010"
replace oes_occ_code = "47-5041" if occ_lbl == "Mining machine operators 47-5040"
replace oes_occ_code = "49-2021" if occ_lbl == "Radio and telecommunications equipment installers and repairers 49-2020"
replace oes_occ_code = "49-3041" if occ_lbl == "Heavy vehicle and mobile equipment service technicians and mechanics 49-3040"
replace oes_occ_code = "49-3051" if occ_lbl == "Small engine mechanics 49-3050"
replace oes_occ_code = "49-3091" if occ_lbl == "Miscellaneous vehicle and mobile equipment mechanics, installers, and repairers 49-3090"
replace oes_occ_code = "49-9011" if occ_lbl == "Control and valve installers and repairers 49-9010"
replace oes_occ_code = "49-9043" if occ_lbl == "Maintenance and repair workers, general 49-9042"
replace oes_occ_code = "49-9061" if occ_lbl == "Precision instrument and equipment repairers 49-9060"
replace oes_occ_code = "51-2028" if occ_lbl == "Electrical, electronics, and electromechanical assemblers 51-2020"
replace oes_occ_code = "51-2091" if occ_lbl == "Miscellaneous assemblers and fabricators 51-2090"
replace oes_occ_code = "51-3021" if occ_lbl == "Butchers and other meat, poultry, and fish processing workers 51-3020"
replace oes_occ_code = "51-3093" if occ_lbl == "Food processing workers, all other 51-3099"
replace oes_occ_code = "51-4011" if occ_lbl == "Computer control programmers and operators 51-4010"
replace oes_occ_code = "51-4051" if occ_lbl == "Metal furnace and kiln operators and tenders 51-4050"
replace oes_occ_code = "51-4071" if occ_lbl == "Molders and molding machine setters, operators, and tenders, metal and plastic 51-4070"
replace oes_occ_code = "51-4121" if occ_lbl == "Welding, soldering, and brazing workers 51-4120"
replace oes_occ_code = "51-4191" if occ_lbl == "Metalworkers and plastic workers, all other 51-4199"
replace oes_occ_code = "51-6051" if occ_lbl == "Tailors, dressmakers, and sewers 51-6050"
replace oes_occ_code = "51-7042" if occ_lbl == "Woodworkers, all other 51-7099"
replace oes_occ_code = "51-8013" if occ_lbl == "Power plant operators, distributors, and dispatchers 51-8010"
replace oes_occ_code = "51-8091" if occ_lbl == "Miscellaneous plant and system operators 51-8090"
replace oes_occ_code = "51-9011" if occ_lbl == "Chemical processing machine setters, operators, and tenders 51-9010"
replace oes_occ_code = "51-9021" if occ_lbl == "Crushing, grinding, polishing, mixing, and blending workers 51-9020"
replace oes_occ_code = "51-9031" if occ_lbl == "Cutting workers 51-9030"
replace oes_occ_code = "51-9081" if occ_lbl == "Medical, dental, and ophthalmic laboratory technicians 51-9080"
replace oes_occ_code = "51-9151" if occ_lbl == "Photographic process workers and processing machine operators 51-9130"
replace oes_occ_code = "53-1048" if occ_lbl == "Supervisors, transportation and material moving workers 53-1000"
replace oes_occ_code = "53-2011" if occ_lbl == "Aircraft pilots and flight engineers 53-2010"
replace oes_occ_code = "53-2021" if occ_lbl == "Air traffic controllers and airfield operations specialists 53-2020"
replace oes_occ_code = "53-3021" if occ_lbl == "Bus drivers 53-3020"
replace oes_occ_code = "53-3031" if occ_lbl == "Driver/sales workers and truck drivers 53-3030"
replace oes_occ_code = "53-3041" if occ_lbl == "Motor vehicle operators, all other 53-3099"
replace oes_occ_code = "53-4011" if occ_lbl == "Locomotive engineers and operators 53-4010"
replace oes_occ_code = "53-5021" if occ_lbl == "Ship and boat captains and operators 53-5020"
replace oes_occ_code = "53-7031" if occ_lbl == "Dredge, excavating, and loading machine operators 53-7030"
replace oes_occ_code = "53-7071" if occ_lbl == "Pumping station operators 53-7070"
replace oes_occ_code = "53-7121" if occ_lbl == "Material moving workers, all other 53-7199"

*** Case 2: Conflicting Telework Indicator between ATL and DN ***
*** Action: Determine Telework indicator, then choose occupation code with the closest meaning

replace oes_occ_code = "33-9092"  if occ_lbl == "Lifeguards and other recreational and all other protective service workers 33-909X"
// 33-9091	Crossing Guards	0
// 33-9092	Lifeguards, Ski Patrol, and Other Recreational Protective Service Workers	0
// 33-9093	Transportation Security Screeners	0
// 33-9099	Protective Service Workers, All Other	1

replace oes_occ_code = "21-1091"  if occ_lbl == "Miscellaneous community and social service specialists, including health educators and community health workers 21-109X"
// 21-1091	Health Educators	0
// 21-1092	Probation Officers and Correctional Treatment Specialists	1
// 21-1093	Social and Human Service Assistants	0
// 21-1094	Community Health Workers	0

replace oes_occ_code = "31-9091"  if occ_lbl == "Miscellaneous healthcare support occupations, including medical equipment preparers 31-909X"
// 31-9091	Dental Assistants	0
// 31-9092	Medical Assistants	0
// 31-9093	Medical Equipment Preparers	0
// 31-9094	Medical Transcriptionists	1
// 31-9095	Pharmacy Aides	0
// 31-9096	Veterinary Assistants and Laboratory Animal Caretakers	0
// 31-9097	Phlebotomists	0
// 31-9099	Healthcare Support Workers, All Other	.3150525

replace oes_occ_code = "25-9011"  if occ_lbl == "Other education, training, and library workers 25-90XX"
// 25-9011	Audio-Visual and Multimedia Collections Specialists	1
// 25-9021	Farm and Home Management Advisors	0
// 25-9031	Instructional Coordinators	1
// 25-9041	Teacher Assistants	1

replace oes_occ_code = "49-9092"  if occ_lbl == "Other installation, maintenance, and repair workers 49-909X"
// 49-9091	Coin, Vending, and Amusement Machine Servicers and Repairers	1
// 49-9092	Commercial Divers	0
// 49-9093	Fabric Menders, Except Garment	0
// 49-9094	Locksmiths and Safe Repairers	0
// 49-9095	Manufactured Building and Mobile Home Installers	0
// 49-9096	Riggers	0
// 49-9097	Signal and Track Switch Repairers	0
// 49-9098	Helpers--Installation, Maintenance, and Repair Workers	0
// 49-9099	Installation, Maintenance, and Repair Workers, All Other	0

replace oes_occ_code = "11-9032"  if occ_lbl == "Education administrators (11-9030)"
// 11-9031	Education Administrators, Preschool and Childcare Center/Program	0
// 11-9032	Education Administrators, Elementary and Secondary School	1
// 11-9033	Education Administrators, Postsecondary	1
// 11-9039	Education Administrators, All Other	1

replace oes_occ_code = "13-1031"  if occ_lbl == "Claims adjusters, appraisers, examiners, and investigators 13-1030"
// 13-1031	Claims Adjusters, Examiners, and Investigators	1
// 13-1032	Insurance Appraisers, Auto Damage	0

replace oes_occ_code = "17-2021"  if occ_lbl == "Surveyors, cartographers, and photogrammetrists 17-1020"
// 17-1021	Cartographers and Photogrammetrists	1
// 17-1022	Surveyors	.3928129

replace oes_occ_code = "17-2112"  if occ_lbl == "Industrial engineers, including health and safety 17-2110"
// 17-2111	Health and Safety Engineers, Except Mining Safety Engineers and Inspectors	.343295
// 17-2112	Industrial Engineers	.4186046

replace oes_occ_code = "17-3029"  if occ_lbl == "Engineering technicians, except drafters 17-3020"
// 17-3021	Aerospace Engineering and Operations Technicians	0
// 17-3022	Civil Engineering Technicians	1
// 17-3023	Electrical and Electronics Engineering Technicians	0
// 17-3024	Electro-Mechanical Technicians	0
// 17-3025	Environmental Engineering Technicians	0
// 17-3026	Industrial Engineering Technicians	0
// 17-3027	Mechanical Engineering Technicians	0
// 17-3029	Engineering Technicians, Except Drafters, All Other	0

replace oes_occ_code = "19-1011"  if occ_lbl == "Agricultural and food scientists 19-1010"
// 19-1011	Animal Scientists	1
// 19-1012	Food Scientists and Technologists	0
// 19-1013	Soil and Plant Scientists	1

replace oes_occ_code = "19-1021"  if occ_lbl == "Biological scientists 19-1020"
// 19-1021	Biochemists and Biophysicists	0
// 19-1022	Microbiologists	0
// 19-1023	Zoologists and Wildlife Biologists	1
// 19-1029	Biological Scientists, All Other	.7094972

replace oes_occ_code = "19-1032"  if occ_lbl == "Conservation scientists and foresters 19-1030"
// 19-1031	Conservation Scientists	.3236994
// 19-1032	Foresters	0

replace oes_occ_code = "19-3091" if occ_lbl == "Miscellaneous social scientists and related workers 19-3090"
// 19-3091	Anthropologists and Archeologists	1
// 19-3092	Geographers	1
// 19-3093	Historians	0
// 19-3094	Political Scientists	1
// 19-3099	Social Scientists and Related Workers, All Other	1

replace oes_occ_code = "19-4091" if occ_lbl == "Miscellaneous life, physical, and social science technicians 19-4090"
// 19-4091	Environmental Science and Protection Technicians, Including Health	0
// 19-4092	Forensic Science Technicians	0
// 19-4093	Forest and Conservation Technicians	0
// 19-4099	Life, Physical, and Social Science Technicians, All Other	.5376737

replace oes_occ_code = "21-1012" if occ_lbl == "Counselors 21-1010"
// 21-1012	Educational, Guidance, School, and Vocational Counselors	1
// 21-1013	Marriage and Family Therapists	1
// 21-1015	Rehabilitation Counselors	1
// 21-1018	Substance Abuse, Behavioral Disorder, and Mental Health Counselors	.5

replace oes_occ_code = "25-4011" if occ_lbl == "Archivists, curators, and museum technicians 25-4010"
// 25-4011	Archivists	1
// 25-4012	Curators	1
// 25-4013	Museum Technicians and Conservators	0

replace oes_occ_code = "27-1011" if occ_lbl == "Artists and related workers 27-1010"
// 27-1011	Art Directors	1
// 27-1012	Craft Artists	0
// 27-1013	Fine Artists, Including Painters, Sculptors, and Illustrators	1
// 27-1014	Multimedia Artists and Animators	1

replace oes_occ_code = "27-1021" if occ_lbl == "Designers 27-1020"
// 27-1021	Commercial and Industrial Designers	1
// 27-1022	Fashion Designers	1
// 27-1023	Floral Designers	1
// 27-1024	Graphic Designers	1
// 27-1025	Interior Designers	1
// 27-1026	Merchandise Displayers and Window Trimmers	0
// 27-1027	Set and Exhibit Designers	1

replace oes_occ_code = "27-2042" if occ_lbl == "Musicians, singers, and related workers 27-2040"
// 27-2041	Music Directors and Composers	.4378613
// 27-2042	Musicians and Singers	0

replace oes_occ_code = "27-3011" if occ_lbl == "Announcers 27-3010"
// 27-3011	Radio and Television Announcers	0
// 27-3012	Public Address System and Other Announcers	1

replace oes_occ_code = "27-3022" if occ_lbl == "News analysts, reporters and correspondents 27-3020"
// 27-3021	Broadcast News Analysts	0
// 27-3022	Reporters and Correspondents	1

replace oes_occ_code = "27-4032" if occ_lbl == "Television, video, and motion picture camera operators and editors 27-4030"
// 27-4031	Camera Operators, Television, Video, and Motion Picture	0
// 27-4032	Film and Video Editors	1

replace oes_occ_code = "29-1061" if occ_lbl == "Physicians and surgeons 29-1060"
// 29-1061	Anesthesiologists	0
// 29-1062	Family and General Practitioners	0
// 29-1063	Internists, General	0
// 29-1064	Obstetricians and Gynecologists	0
// 29-1065	Pediatricians, General	0
// 29-1066	Psychiatrists	1
// 29-1067	Surgeons	0
// 29-1069	Physicians and Surgeons, All Other	.1046015

replace oes_occ_code = "29-1122" if occ_lbl == "Audiologists 29-1121"
replace oes_occ_code = "29-1123" if occ_lbl == "Therapists, all other 29-1129"
// 29-1122	Occupational Therapists	0
// 29-1123	Physical Therapists	0
// 29-1124	Radiation Therapists	0
// 29-1125	Recreational Therapists	.7478685
// 29-1126	Respiratory Therapists	0
// 29-1127	Speech-Language Pathologists	1
// 29-1128	Exercise Physiologists	0

replace oes_occ_code = "29-9011" if occ_lbl == "Other healthcare practitioners and technical occupations 29-9000"
// 29-9011	Occupational Health and Safety Specialists	0
// 29-9012	Occupational Health and Safety Technicians	0
// 29-9091	Athletic Trainers	1
// 29-9092	Genetic Counselors	1
// 29-9099	Healthcare Practitioners and Technical Workers, All Other	0

replace oes_occ_code = "35-2011" if occ_lbl == "Cooks 35-2010"
// 35-2011	Cooks, Fast Food	0
// 35-2012	Cooks, Institution and Cafeteria	0
// 35-2013	Cooks, Private Household	1
// 35-2014	Cooks, Restaurant	0
// 35-2015	Cooks, Short Order	0

replace oes_occ_code = "39-3011" if occ_lbl == "Gaming services workers 39-3010"
// 39-3011	Gaming Dealers	1
// 39-3012	Gaming and Sports Book Writers and Runners	0

replace oes_occ_code = "39-5092" if occ_lbl == "Miscellaneous personal appearance workers 39-5090"
// 39-5091	Makeup Artists, Theatrical and Performance	1
// 39-5092	Manicurists and Pedicurists	0
// 39-5093	Shampooers	0
// 39-5094	Skincare Specialists	0

replace oes_occ_code = "39-9031" if occ_lbl == "Recreation and fitness workers 39-9030"
// 39-9031	Fitness Trainers and Aerobics Instructors	0
// 39-9032	Recreation Workers	1

replace oes_occ_code = "41-9012" if occ_lbl == "Models, demonstrators, and product promoters 41-9010"
// 41-9011	Demonstrators and Product Promoters	0
// 41-9012	Models	1

replace oes_occ_code = "41-9021" if occ_lbl == "Real estate brokers and sales agents 41-9020"
// 41-9021	Real Estate Brokers	1
// 41-9022	Real Estate Sales Agents	0

replace oes_occ_code = "43-4121" if occ_lbl == "Information and record clerks, all other 43-4199"
// 43-4111	Interviewers, Except Eligibility and Loan	1
// 43-4121	Library Assistants, Clerical	0
// 43-4131	Loan Interviewers and Clerks	0
// 43-4141	New Accounts Clerks	0
// 43-4151	Order Clerks	1
// 43-4161	Human Resources Assistants, Except Payroll and Timekeeping	1
// 43-4171	Receptionists and Information Clerks	0
// 43-4181	Reservation and Transportation Ticket Agents and Travel Clerks	0

replace oes_occ_code = "43-5031" if occ_lbl == "Dispatchers 43-5030"
// 43-5031	Police, Fire, and Ambulance Dispatchers	0
// 43-5032	Dispatchers, Except Police, Fire, and Ambulance	1

replace oes_occ_code = "51-6091" if occ_lbl == "Textile, apparel, and furnishings workers, all other 51-6099"
// 51-6091	Extruding and Forming Machine Setters, Operators, and Tenders, Synthetic and Glass Fibers	0
// 51-6092	Fabric and Apparel Patternmakers	1
// 51-6093	Upholsterers	0

replace oes_occ_code = "51-9121" if occ_lbl == "Painting workers 51-9120"
// 51-9121	Coating, Painting, and Spraying Machine Setters, Operators, and Tenders	0
// 51-9122	Painters, Transportation Equipment	0
// 51-9123	Painting, Coating, and Decorating Workers	1

merge m:1 oes_occ_code using `onet_temp'

keep if _merge == 3
drop _merge 

* Define 3 periods 
gen pre_period  = inrange(date_monthly, tm(2016m1), tm(2019m12))
gen inf_period  = inrange(date_monthly, tm(2021m4), tm(2023m5))
gen post_period = inrange(date_monthly, tm(2023m6), tm(2024m12))

gen str10 period = ""
replace period = "pre"  if pre_period == 1
replace period = "inf"  if inf_period == 1
replace period = "post" if post_period == 1

* will use this variable to see the number of observations in each bin 
gen obs = 1

* create telworkable groups 
gen str6 tel_group = ""

replace tel_group = "no" if teleworkable == 0
replace tel_group = "some" if teleworkable > 0 & teleworkable < 1
replace tel_group = "high" if teleworkable == 1


* we observe the Dingel-Neiman measure of exposure to teleworkability on the interval [0,1] so we split our sample into 
* 2 groups - high or some teleworkable exposure on (0,1] and no teleworkable {0}. 

replace teleworkable = ceil(teleworkable)

* Define a new label
label define teleworkable_lbl 0 "no_wfh" 1 "high_wfh"

* Apply it to the variable
label values teleworkable teleworkable_lbl


***** Wage Growth by Quartile x Education *****

* take the median wage growth for each group (this is consistent with the aggregation done by the atlanta fed for their aggregate series)

preserve 
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, by(date_monthly wagegroup teleworkable)

* smooth the series 
sort wagegroup teleworkable date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12


rename smoothed_med_w_growth smwg

decode teleworkable, gen(teleworkable_lbl)

gen group = wagegroup + "_" + teleworkable_lbl

keep date_monthly group smwg
reshape wide smw, i(date_monthly) j(group) string

keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$output_dir/figure_2_5_temp1.csv", replace 
restore 
******************************************************************************************


**** Pooled *****

preserve 
collapse (median) med_w_growth = wagegrowthtracker83 (sum) wgt = obs, by(date_monthly teleworkable)

* smooth the series 
sort teleworkable date_monthly

* 3-month moving average
gen smoothed_med_w_growth = ( ///
    med_w_growth + ///
    med_w_growth[_n-1] + med_w_growth[_n-2] + med_w_growth[_n-3] + med_w_growth[_n-4] + med_w_growth[_n-5] + ///
    med_w_growth[_n-6] + med_w_growth[_n-7] + med_w_growth[_n-8] + med_w_growth[_n-9] + med_w_growth[_n-10] + ///
    med_w_growth[_n-11]) / 12


rename smoothed_med_w_growth smwg

decode teleworkable, gen(teleworkable_lbl)

gen group = teleworkable_lbl

keep date_monthly group smwg
reshape wide smw, i(date_monthly) j(group) string

keep if date_monthly >= tm(2016m1)

* now we have our wage growth measure for each wage group {1,2,3,4} x work-from-home exposure group {low, high}
export delimited "$output_dir/figure_2_5_temp2.csv", replace 
restore 