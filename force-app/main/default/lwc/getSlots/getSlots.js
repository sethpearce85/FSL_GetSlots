import { api, track, wire, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAppointmentDetails from '@salesforce/apex/GetSlotsHelper.getAppointmentDetails';
import getSlots from '@salesforce/apex/GetSlotsHelper.getSlots';
import submitServiceAppt from '@salesforce/apex/GetSlotsHelper.submitServiceAppt';
export default class GetSlots extends NavigationMixin(LightningElement) {

    @api recordId;
    @api inApp;
    @api quoteId;
    appointment = {};
    error;
    @api slots = [];

    availableToBook = false;
    inAppAlreadyBooked = false;
    hasSlots = false;
    noSlots = false;
    policy = 'zip';
    loading = false;
    showDetail = true;
    policyName;


    connectedCallback(){
        this.loading = true;
    
        getAppointmentDetails({recordId: this.recordId, policy: this.policy})
            .then( result => {
                this.init = true;
                console.log(result);
                this.appointment = result;
                console.log('sa id ---> '+this.appointment);
                this.workType = this.appointment.Work_Order__r.WorkType.Name;
                this.workOrderNumber = this.appointment.Work_Order__r.WorkOrderNumber;
                this.street = this.appointment.Address.street;
                this.territory = this.appointment.ServiceTerritory.Name;
                this.loading = false;
                this.availableToBook = this.appointment.Status == 'None' ? true : false; 
                this. inAppAlreadyBooked = this.appointment.Status != 'None' && this.inApp == true ? true : false;
                console.log('Available To Book ' +  this.availableToBook)
             
            })
            .catch( error => {
                this.error = error;
                console.log('error ---> '+this.error);
                
            })
        

    }

    fetchSlots(event){
        console.log('clicked');
        
        this.policy = event.currentTarget.dataset.policy;
        if(this.policy === "zip"){
            this.policyName = 'Sales Route Zip Policy';
        }
        else{
            this.policyName = 'OSP Zip Assignment Policy';
        }

        console.log(this.policy);
        console.log(this.policyName);
        this.loading = true;
        this.noSlots = false;

        getSlots(({saId: this.appointment.Id, policy: this.policy}))
        .then( result => {
            this.showDetail = false;
            console.log(JSON.parse(result));
            this.slots = JSON.parse(result);
            console.log('slots---->'+JSON.stringify(this.slots));
            this.loading = false;

            if(this.slots.length > 0){
                this.hasSlots = true;
                this.noSlots = false;
            }else{
                this.noSlots = true;
            }
            
        })
        .catch(error => {
            this.error = error;
            this.loading = false;
        })

    }

    selectSlot(event){

        let start = event.currentTarget.dataset.starttime;
        let end = event.currentTarget.dataset.endtime;
        this.loading = true;
        
        submitServiceAppt(({saId: this.appointment.Id, startTime: start, endTime: end, policy: this.policy }))
        .then( result => {
           setTimeout(() => {
                this.navigateToViewServiceApptPage()
            }, 13000)
        })
        .catch(error => {
            this.error = error;
            this.loading = false;
        })
    }

    handleCancel(event){
        this.hasSlots = false;
        this.noSlots = false;
        this.slots = [];
        this.showDetail = true;
    }

    // Navigate to View Service Appointment Page
    navigateToViewServiceApptPage() {
        this.availableToBook = false;
        this.loading = false;
        console.log('navigate to SA page!!!');

        window.location.href = window.location.origin + '/' + this.appointment.Id;
    }

}