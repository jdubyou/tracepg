#!/usr/sbin/dtrace -s

#pragma D option quiet
#pragma D option defaultargs
#pragma D option switchrate=10hz

dtrace:::BEGIN
{
	printf("Tracing sql queires.. Hit Ctrl-C to end.\n");
	min_ns = $1 * 1000000;
	timezero = timestamp;
	
}

postgresql*:::query-start
{
	self->start = timestamp;
	self->vstart = vtimestamp;
	self->query = copyinstr(arg0);
}

postgresql*:::query-execute-start
{
	self->estart = timestamp;
}

postgresql*:::query-execute-done
/self->start/
{
	self->exec = timestamp - self->estart;
	self->estart = 0;
}

postgresql*:::query-done
/self->start && (timestamp - self->start) >= min_ns /
/*&& strstr(self->query, $$2) != NULL */
{
	@query_time[self->query] = quantize(timestamp - self->start);
}

postgresql*:::query-done
{
	self->start = 0; 
    self->vstart = 0; 
    self->exec = 0;
}
dtrace:::END
{
    printf("PostGresSQL lantency (ns \n");
    printa(@query_time);
}
