import { LightningElement, wire } from 'lwc';
import getMessage from '@salesforce/apex/CopadoDemoController.getMessage';

export default class CopadoDemo extends LightningElement {
    message = 'Loading...';

    @wire(getMessage)
    wiredMessage({ data, error }) {
        if (data) {
            this.message = data;
        } else if (error) {
            this.message = 'Error loading message';
            console.error(error);
        }
    }
}