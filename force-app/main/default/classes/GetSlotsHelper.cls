public with sharing class GetSlotsHelper {

@AuraEnabled
public static ServiceAppointment getAppointmentDetails(String recordId){
    try {
        system.debug('record id----->'+recordId);

        return [
                    SELECT 
                        Id, 
                        SchedStartTime,
                        SchedEndTime, 
                        ServiceTerritoryId, 
                        ServiceTerritory.Name,
                        ServiceTerritory.OperatingHoursId, 
                        Address, 
                        AppointmentNumber,
                        Work_Order__r.WorkOrderNumber, 
                        Work_Order__r.WorkType.Name, 
                        Work_Order__r.Id, 
                        Work_Order__r.Service_Window_End_Date__c,
                        Work_Order__r.Service_Window_Start_Date__c, 
                        Status
                    FROM ServiceAppointment
                    WHERE Work_Order__r.Id =: recordId
                    LIMIT 1];
          
        
    } catch (Exception e) {
        system.debug(e);
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled
public static String getSlots(String saId, String policy){
    try {

        FSL_Scheduling_Policy_Tuner__c fsl_isp_schedulingPolicyId = FSL_Scheduling_Policy_Tuner__c.getOrgDefaults();
        String fsl_salesZipPolicyId = fsl_isp_schedulingPolicyId.FSL_Zip_Scheduling_Policy_Id__c;
        String fsl_SecondaryPolicyId = fsl_isp_schedulingPolicyId.FSL_Secondary_Scheduling_Policy__c;
        Id fslSchedPolicyId;
        String tempFSL_Id;
        if(policy == 'zip'){
            fslSchedPolicyId = (Id)fsl_salesZipPolicyId;
        }
        else{
            fslSchedPolicyId = (Id)fsl_SecondaryPolicyId;
        }
      

        List<FSL__Scheduling_Policy__c> fslSchedulePolicyLst = [
            SELECT 
                Id, 
                Name
            FROM FSL__Scheduling_Policy__c
            WHERE Id = :fslSchedPolicyId
        ];

        if(fslSchedulePolicyLst.size() > 0){
            fslSchedPolicyId = fslSchedulePolicyLst[0].Id;
            Boolean FLS_schedFound = true;
            system.debug('SCHED POLICY --->'+fslSchedPolicyId);
        }

        ServiceAppointment sa = [
                                    SELECT 
                                        Id, 
                                        ServiceTerritory.OperatingHoursId
                                    FROM ServiceAppointment
                                    WHERE Id =: saId
                                    LIMIT 1
        ];

        
        

        Map<String, List<SlotWrapper>> dateAppointmentSlotWrapperLstMap = new Map<String, List<SlotWrapper>>();
           
        //String operatingHoursStrId = '0OH3o000000PDzlGAG'; // phx branch operating hours -- default 
        //Id ServiceId = (Id)saId;
        //system.debug('SA ----->'+ saId);
        
        Id operatingHoursId = sa.ServiceTerritory.OperatingHoursId;
        Boolean exactAppointment = false; // true = exact appt, false = range 
        //TimeZone tz = UserInfo.getTimeZone();

        operatinghours oh = new operatinghours();
        oh = [
                SELECT Id,TimeZone,
                    (
                        SELECT EndTime, StartTime, Type, DayOfWeek 
                        FROM TimeSlots
                    ) 
                FROM OperatingHours 
                WHERE Id=:operatingHoursId 
                LIMIT 1
            ];
        
        TimeZone tz = TimeZone.getTimeZone(oh.TimeZone);
        System.debug('OH --->'+oh.Id+' fslSchedPolicyId --> '+fslSchedPolicyId+' tz---> '+tz);

        List<FSL.AppointmentBookingSlot> appointmentSlotsLst = FSL.AppointmentBookingService.GetSlots(sa.Id, fslSchedPolicyId, oh, tz, exactAppointment);

        //system.debug(JSON.serialize(appointmentSlotsLst));

        system.debug('Slot List Size ---> '+ appointmentSlotsLst.size());
        List<SlotWrapper> slotWrapperList = new List<SlotWrapper>();
        List<SlotDateArray> dateSlotArray= new List<SlotDateArray>();
        Integer i = 0;
        for(FSL.AppointmentBookingSlot slot : appointmentSlotsLst){
            system.debug('Slot --> '+ slot);
            system.debug('Slot:'+i+' Start: '+slot.Interval.Start+' Finish:'+ slot.Interval.Finish+' Grade: '+slot.Grade);
            i++;
            slotWrapperList.add(new SlotWrapper(slot.interval));
        }

        for(SlotWrapper slot : slotWrapperList){
            if(dateAppointmentSlotWrapperLstMap.containsKey(String.valueOf(slot.slotDate))){
                dateAppointmentSlotWrapperLstMap.get(String.valueOf(slot.slotDate)).add(slot);
            }
            else{
                dateAppointmentSlotWrapperLstMap.put(String.valueof(slot.slotDate), new List<SlotWrapper>{slot});
            }
        }

        for(String s : dateAppointmentSlotWrapperLstMap.keySet()){
            SlotDateArray tempSDA = new SlotDateArray(s, dateAppointmentSlotWrapperLstMap.get(s));
            dateSlotArray.add(tempSDA);
        }

        system.debug(dateSlotArray);
        //return JSON.serialize(dateAppointmentSlotWrapperLstMap);
        return JSON.serialize(dateSlotArray);
    
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled
public static String submitServiceAppt(String saId, String startTime, String endTime, String policy){
    try {
        system.debug(startTime);
        system.debug(endTime);
        system.debug(saId);
        system.debug(policy);

        //2022-04-20T07:00:00.000Z
        FSL_Scheduling_Policy_Tuner__c fsl_isp_schedulingPolicyId = FSL_Scheduling_Policy_Tuner__c.getOrgDefaults();
        String fsl_salesZipPolicyId = fsl_isp_schedulingPolicyId.FSL_Zip_Scheduling_Policy_Id__c;
        String fsl_SecondaryPolicyId = fsl_isp_schedulingPolicyId.FSL_Secondary_Scheduling_Policy__c;
        Id fslSchedPolicyId;
        if(policy == 'zip'){
            fslSchedPolicyId = (Id)fsl_salesZipPolicyId;
        }
        else{
            fslSchedPolicyId = (Id)fsl_SecondaryPolicyId;
        }

        ServiceAppointment servAppt = [   SELECT Id, ServiceTerritory.OperatingHoursId 
                                    FROM ServiceAppointment 
                                    WHERE Id =: saId 
                                    LIMIT 1
                                    ];

        Id operatingHoursId = servAppt.ServiceTerritory.OperatingHoursId;
        

        operatinghours oh = new operatinghours();
        oh = [
                SELECT Id,TimeZone,
                    (
                        SELECT EndTime, StartTime, Type, DayOfWeek 
                        FROM TimeSlots
                    ) 
                FROM OperatingHours 
                WHERE Id=:operatingHoursId 
                LIMIT 1
            ];
        
        TimeZone tz = TimeZone.getTimeZone(oh.TimeZone);


        Datetime windowStart = TerminixCloudUtils.isoStringToGmtDateTime(startTime);
        system.debug(windowStart);

        

        TimeZone userTimeZone = UserInfo.getTimeZone();
        Integer offset = userTimeZone.getOffset(windowStart);
        system.debug(offset);
        DateTime convertedStartDateTime = Datetime.newInstance(windowStart.date(), windowStart.time() - offset);
        system.debug(convertedStartDateTime);


        Datetime windowEnd = TerminixCloudUtils.isoStringToGmtDateTime(endTime);
        system.debug(windowEnd);

        Integer endoffset = userTimeZone.getOffset(windowEnd);
        system.debug(endoffset);
        DateTime convertedEndDateTime = Datetime.newInstance(windowEnd.date(), windowEnd.time() - endoffset);
        system.debug(convertedEndDateTime);

        Integer finalStartOffset = tz.getOffset(convertedStartDateTime);
        DateTime finalConvertedStartTime = Datetime.newInstance(windowStart.date(), windowStart.time() - finalStartOffset);
        system.debug(finalConvertedStartTime);

        Integer finalEndOffset = tz.getOffset(convertedEndDateTime);
        DateTime finalConvertedEndTime = Datetime.newInstance(windowEnd.date(), windowEnd.time() - finalEndOffset);
        system.debug(finalConvertedEndTime);

        Id servApptId = saId;

        ServiceAppointment sa = new ServiceAppointment(
            Id = saId,
            ArrivalWindowStartTime = finalConvertedStartTime,
            ArrivalWindowEndTime = finalConvertedEndTime
        );
        
        update sa;

        TerminixCloudServiceApptReschedule.bookAppointment(fslSchedPolicyId, saId);

        return 'Success';

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

class SlotDateArray {
    List<SlotWrapper> slots = new List<SlotWrapper>();
    String dateKey; 
    SlotDateArray(String k, List<SlotWrapper> s){
        this.slots = s;
        this.datekey = k;
    }
}

class SlotWrapper{
    public Datetime startTime, endTime;
    public String slotDate; 
    public Time startHour, endHour; 
    SlotWrapper(FSL.TimeInterval interval){
        this.startTime = interval.start;
        this.endTime = interval.finish;
        this.slotDate = startTime.format('EEE, MMMM dd, yyyy');
        this.startHour = startTime.timeGMT();
        this.endhour = endTime.timeGMT();
    }
}

}
