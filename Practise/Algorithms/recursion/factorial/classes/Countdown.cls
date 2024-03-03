public without sharing class Countdown {

    public void execute(Integer seconds) {
        if (seconds == 0) {
            System.debug('Time out!!!');
        } else {
            System.debug(seconds);
            this.execute(seconds - 1);
        }
    }

}