@IsTest
public class GetSlotsHelperTest {

    static ServiceTerritory terr = new ServiceTerritory();
    static Business_Unit__c branch = new Business_Unit__c();
    static SBQQ__Quote__c quote = new SBQQ__Quote__c();
    static WorkType type = new WorkType();
    static Account acc = new Account();
    static ServiceContract scon = new ServiceContract();
    static Opportunity opp = new Opportunity();
    static Product2 prod = new Product2();
    static PricebookEntry pbe = new PricebookEntry();
    static SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
    static Schema.Location loc = new Schema.Location();
    static OperatingHours objOperatingHours = new OperatingHours();
    static FSL_Scheduling_Policy_Tuner__c setting = new FSL_Scheduling_Policy_Tuner__c();
    static FSL__Scheduling_Policy__c sp = new FSL__Scheduling_Policy__c(Name='Test Policy, not default');
    static ServiceResource serviceResourceRecord = new ServiceResource();
    static Route__c route = new Route__c();
    static Route_Coverage__c rc = new Route_Coverage__c();
    static ServiceTerritoryMember stm = new ServiceTerritoryMember();
    static WorkOrder wo = new WorkOrder();
    



    @isTest 
    public static void testGetSlots(){

        createData();
        ServiceAppointment servAppt = [Select Id,ServiceTerritoryId from ServiceAppointment where Work_Order__r.Id =: wo.Id limit 1];
        String saId = servAppt.Id;
        system.debug('terr---> '+terr.Id+'  SA Terr Id --->'+servAppt.ServiceTerritoryId+ ' SERV Resource ---> '+serviceResourceRecord.Branch__r.Service_Territory__c);
        String policy = 'zip';

        Test.startTest();
        String s = GetSlotsHelper.getSlots(saId, policy);
        system.debug(s);
        
        Test.stopTest();


    }

    @isTest 
    public static void testGetDetails(){
        createData();

        Test.startTest();
        ServiceAppointment s = GetSlotsHelper.getAppointmentDetails(wo.Id);
        Test.stopTest();

    }

    @isTest 
    public static void testSubmitServAppt(){
        createData();
        String saId = [Select Id from ServiceAppointment where Work_Order__r.Id =: wo.Id limit 1][0].Id;
        String startTime = '2022-04-20T07:00:00.000Z';
        String endTime = '2022-04-20T07:00:00.000Z';
        String policy = 'zip';

        Test.startTest();
        String s = GetSlotsHelper.submitServiceAppt(saId, startTime, endTime, policy);
        Test.stopTest();


    }
    

    public static void createData(){
        
        
        
        objOperatingHours.Name = 'Test OP Hours';
        objOperatingHours.TimeZone = 'America/Phoenix';
        upsert objOperatingHours;

        branch.Branch_Manager__c = UserInfo.getUserId();
		branch.Status__c = 'Active';
		insert branch;
		
        terr.Name = 'testPopulateTerritory Territory';
        terr.IsActive = true;
		terr.Business_Unit__c = branch.Id;
		terr.Territory_Function__c = 'PRD';//PRD (service) SLS (sales) -- was GEN
        terr.OperatingHoursId = objOperatingHours.Id;
        insert terr;

        branch.Service_Territory__c = terr.Id;
        update branch;
		
        type.Name = 'Residential Pest Control Initial';
        type.External_Id__c = 'RGPCREG';
        type.DurationType = 'Minutes';
        type.EstimatedDuration = 25;
        type.Service_Line__c = 'PC';
        type.Service_Type__c = 'INI';
        type.Market_Type__c = 'Residential';
        type.Description = 'Test Value';
		insert type;

        
        acc.BillingStreet = '15252 North 67th Avenue';
        acc.BillingStateCode = 'AZ';
        acc.BillingState = 'AZ';
        acc.BillingCity = 'Peoria';
        acc.BillingCountry = 'USA';
        acc.BillingCountryCode='US';
        acc.BillingPostalCode = '85381';
        acc.Name = 'testAccountforTestClass';
        insert acc;

        loc = TestDataHelper2.createLocation(acc.Id);
        loc.Branch__c = branch.Id;
        update loc;
        
        scon.Name = 'Test Service Contract';
        scon.Status__c = 'Active';
        scon.Pricebook2Id = Test.getStandardPricebookId();
        scon.AccountId = acc.Id;
        scon.ContactId = TestDataHelper2.createContact(scon.AccountId).Id;
        scon.Service_Location__c = loc.Id;
        
        
        //Opportunity Creation
        
        opp.Name ='testOpptyforTestClass';
        opp.CloseDate = system.today()+4;
        opp.StageName = 'Prospecting';
        opp.AccountId = acc.Id;
        opp.Property__c = scon.Service_Location__c;
        insert opp;

        scon.SBQQSC__Opportunity__c = opp.Id;
        insert scon;
        
       
        quote.SBQQ__Opportunity2__c = opp.Id;
        insert quote;

        
        prod.Finance_Eligible_Product__c = true;
        prod.Name = 'Residential Pest Control Initial';
        prod.ProductCode = 'INI';
        prod.Service_Line__c = 'RGPC';
        prod.Work_Type__c = type.Id;
        insert prod;
        
        
        
        // WorkType type = new WorkType();
        // type.Service_Line__c = 'PC';
        // type.Service_Type__c = 'REG';
        // type.Market_Type__c = 'Commercial';
        // type.Name = 'Test';
        // type.EstimatedDuration = 1.0;
        // type.External_Id__c = 'extId' + Utilities2.getRandomString();
        // type.Description = 'Test Value';
		// insert type;

		// final Id COMMERCIAL_ACCOUNT_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Commercial').getRecordTypeId();

		// Account newAccount = TestDataHelper2.createAccount( false );
		// newAccount.RecordTypeId = COMMERCIAL_ACCOUNT_RT;
		// newAccount.Market_Type__c = 'Commercial';
		// insert newAccount;

		
    

       
       

        List<TimeSlot> objTimeSlots = new List<TimeSlot>();
            
        // Timeslots
        TimeSlot Monday = new TimeSlot();Monday.OperatingHoursId = objOperatingHours.Id;Monday.DayOfWeek = 'Monday';Monday.Type = 'Normal';Monday.StartTime = Time.newInstance(07,0,0,0);Monday.EndTime = Time.newInstance(16,0,0,0);
        TimeSlot Tuesday = new TimeSlot();Tuesday.OperatingHoursId = objOperatingHours.Id;Tuesday.DayOfWeek = 'Tuesday';Tuesday.Type = 'Normal';Tuesday.StartTime = Time.newInstance(07, 0,0,0);Tuesday.EndTime = Time.newInstance(16,0,0,0);
        TimeSlot Wednesday = new TimeSlot();Wednesday.OperatingHoursId = objOperatingHours.Id;Wednesday.DayOfWeek = 'Wednesday';Wednesday.Type = 'Normal';Wednesday.StartTime = Time.newInstance(08, 0,0,0);Wednesday.EndTime = Time.newInstance(16,0,0,0);
        TimeSlot Thursday = new TimeSlot();Thursday.OperatingHoursId = objOperatingHours.Id;Thursday.DayOfWeek = 'Thursday';Thursday.Type = 'Normal';Thursday.StartTime = Time.newInstance(08, 0,0,0);Thursday.EndTime = Time.newInstance(16,0,0,0);
        TimeSlot Friday = new TimeSlot();Friday.OperatingHoursId = objOperatingHours.Id;Friday.DayOfWeek = 'Friday';Friday.Type = 'Normal';Friday.StartTime = Time.newInstance(08, 0,0,0);Friday.EndTime = Time.newInstance(16,0,0,0);
        TimeSlot Saturday = new TimeSlot();Saturday.OperatingHoursId = objOperatingHours.Id;Saturday.DayOfWeek = 'Saturday';Saturday.Type = 'Normal';Saturday.StartTime = Time.newInstance(08, 0,0,0);Saturday.EndTime = Time.newInstance(16,0,0,0);
        TimeSlot Sunday = new TimeSlot();Sunday.OperatingHoursId = objOperatingHours.Id;Sunday.DayOfWeek = 'Sunday';Sunday.Type = 'Normal';Sunday.StartTime = Time.newInstance(08, 0,0,0);Sunday.EndTime = Time.newInstance(16,0,0,0);
        
        TimeSlot ExtMonday = new TimeSlot();ExtMonday.OperatingHoursId = objOperatingHours.Id;ExtMonday.DayOfWeek = 'Monday';ExtMonday.Type = 'Extended';ExtMonday.StartTime = Time.newInstance(16,0,0,0);ExtMonday.EndTime = Time.newInstance(18,0,0,0);objTimeSlots.add(ExtMonday);
        TimeSlot ExtTuesday = new TimeSlot();ExtTuesday.OperatingHoursId = objOperatingHours.Id;ExtTuesday.DayOfWeek = 'Tuesday';ExtTuesday.Type = 'Extended';ExtTuesday.StartTime = Time.newInstance(16,0,0,0);ExtTuesday.EndTime = Time.newInstance(18,0,0,0);objTimeSlots.add(ExtTuesday);
        TimeSlot ExtWednesday = new TimeSlot();ExtWednesday.OperatingHoursId = objOperatingHours.Id;ExtWednesday.DayOfWeek = 'Wednesday';ExtWednesday.Type = 'Extended';ExtWednesday.StartTime = Time.newInstance(16,0,0,0);ExtWednesday.EndTime = Time.newInstance(18,0,0,0);objTimeSlots.add(ExtWednesday);
        TimeSlot ExtThursday = new TimeSlot();ExtThursday.OperatingHoursId = objOperatingHours.Id;ExtThursday.DayOfWeek = 'Thursday';ExtThursday.Type = 'Extended';ExtThursday.StartTime = Time.newInstance(16,0,0,0);ExtThursday.EndTime = Time.newInstance(18,0,0,0);objTimeSlots.add(ExtThursday);
        TimeSlot ExtFriday = new TimeSlot();ExtFriday.OperatingHoursId = objOperatingHours.Id;ExtFriday.DayOfWeek = 'Friday';ExtFriday.Type = 'Extended';ExtFriday.StartTime = Time.newInstance(16,0,0,0);ExtFriday.EndTime = Time.newInstance(18,0,0,0);objTimeSlots.add(ExtFriday);
        TimeSlot ExtSaturday = new TimeSlot();ExtSaturday.OperatingHoursId = objOperatingHours.Id;ExtSaturday.DayOfWeek = 'Saturday';ExtSaturday.Type = 'Extended';ExtSaturday.StartTime = Time.newInstance(16,0,0,0);ExtSaturday.EndTime = Time.newInstance(18,0,0,0);objTimeSlots.add(ExtSaturday);
        TimeSlot ExtSunday = new TimeSlot();ExtSunday.OperatingHoursId = objOperatingHours.Id;ExtSunday.DayOfWeek = 'Sunday';ExtSunday.Type = 'Extended';ExtSunday.StartTime = Time.newInstance(16,0,0,0);ExtSunday.EndTime = Time.newInstance(18,0,0,0);objTimeSlots.add(ExtSunday);
        
        objTimeSlots.add(Monday);
        objTimeSlots.add(Tuesday);
        objTimeSlots.add(Wednesday);
        objTimeSlots.add(Thursday);
        objTimeSlots.add(Friday);
        objTimeSlots.add(Saturday);
        objTimeSlots.add(Sunday);
        upsert objTimeSlots;

        
        insert sp;

        RecordType rt = [SELECT Id FROM RecordType WHERE NamespacePrefix = 'FSL' AND SobjectType = 'FSL__Work_Rule__c' AND DeveloperName = 'Match_Location_Service' LIMIT 1];

        FSL__Work_Rule__c wr = new FSL__Work_Rule__c(
            Name = 'Match Territory',
            FSL__Active__c = true,
            FSL__Boolean_Operator__c = '=',
            FSL__Crew_Resources_Availability__c = false,
            FSL__Description__c = 'Test Work Rule Description',
            FSL__Enable_Overtime__c = false,
            FSL__Is_Fixed_Gap__c = false,
            FSL__isTimephased__c = false,
            FSL__Match_Constant_Boolean_Value__c = true,
            FSL__Match_Skill_Level__c = false,
            FSL__Maximum_Travel_From_Home_Type__c = 'Distance',
            FSL__Pass_Empty_Values__c = false,
            RecordTypeId = rt.Id,
            FSL__Resource_Group_Field__c = '',
            FSL__Resource_Property__c = 'IsActive',
            FSL__Service_Property__c = 'ServiceTerritory',
            FSL__Service_Schedule_Time_Property__c = 'SchedStartTime',
            FSL__Service_Time_Operator__c = 'Before',
            FSL__Service_Time_Property__c = 'EarliestStartTime',
            FSL__Start_of_Day__c = '00:00',
            FSL__Travel_From_Home__c = null,
            FSL__Travel_To_Home__c = null,
            FSL__Object_Group_Field__c = '',
            FSL__Working_Location_Enable_Primary__c = false
        );

        insert wr;

        FSL__Scheduling_Policy_Work_Rule__c spwr = new FSL__Scheduling_Policy_Work_Rule__c(
            FSL__Work_Rule__c = wr.Id,
            FSL__Scheduling_Policy__c = sp.Id
        );

        insert spwr;

        RecordType rt_wo = [SELECT Id FROM RecordType WHERE SobjectType = 'WorkOrder' AND DeveloperName = 'Residential_Pest' LIMIT 1];
       
        setting.Name = 'test setting';
        setting.FSL_Zip_Scheduling_Policy_Id__c = sp.Id;
        setting.ISP_Estimation_Work_Order_RT_ID__c = rt_wo.Id;
        insert setting;
       
        

        serviceResourceRecord.Name='Test Resource';
        serviceResourceRecord.RelatedRecordId=UserInfo.getUserId();
        serviceResourceRecord.Branch__c = branch.Id;
        serviceResourceRecord.IsActive=true;
		insert serviceResourceRecord;

        
        stm.ServiceResourceId = serviceResourceRecord.Id;
        stm.ServiceTerritoryId = terr.Id;
        stm.EffectiveStartDate = System.now().addDays(-100);
        insert stm;

       
        route.Branch__c =branch.Id;
        route.Service_Territory__c = terr.Id;
        route.Route_Owner__c= serviceResourceRecord.Id;
        insert route;

        
        rc.Route__c = route.Id;
        rc.Service_Resource__c = serviceResourceRecord.Id;
        rc.Coverage_Start__c = System.now().addDays(-100);
        insert rc;


        wo.description = 'Test';
        wo.Pricebook2Id = Test.getStandardPricebookId();
        wo.RecordTypeId = setting.ISP_Estimation_Work_Order_RT_ID__c;
        wo.AccountId = acc.Id;
		wo.LocationId = loc.Id;
		wo.ServiceTerritoryId = terr.Id;
		wo.Servicing_Branch_Id__c = branch.Id;
		wo.WorkTypeId = type.Id;
		wo.Service_Window_Start_Date__c = System.today();
		wo.Service_Window_End_Date__c = System.today().addDays(30);
        wo.Route__c = route.Id;
		insert wo;

       

    }


    

}